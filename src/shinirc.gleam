import mvu
import gleam/bytes_builder
import gleam/erlang
import gleam/erlang/process.{type Selector, type Subject}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/json
import gleam/option.{type Option, None}
import gleam/otp/actor
import gleam/result
import lustre
import lustre/attribute
import lustre/element
import lustre/element/html.{html}
import lustre/server_component
import mist.{
  type Connection, type ResponseData, type WebsocketConnection,
  type WebsocketMessage,
}

pub fn main() {
  let assert Ok(_) =
    fn(req: Request(Connection)) -> Response(ResponseData) {
      case request.path_segments(req) {
        ["shinirc"] ->
          mist.websocket(
            request: req,
            on_init: socket_init,
            on_close: socket_close,
            handler: socket_update,
          )

        ["lustre-server-component.mjs"] -> {
          let assert Ok(priv) = erlang.priv_directory("lustre")
          let path = priv <> "/static/lustre-server-component.mjs"

          mist.send_file(path, offset: 0, limit: None)
          |> result.map(fn(script) {
            response.new(200)
            |> response.prepend_header("content-type", "application/javascript")
            |> response.set_body(script)
          })
          |> result.lazy_unwrap(fn() {
            response.new(404)
            |> response.set_body(mist.Bytes(bytes_builder.new()))
          })
        }

        _ ->
          response.new(200)
          |> response.prepend_header("content-type", "text/html")
          |> response.set_body(
            html([], [
              html.head([], [
                html.link([
                  attribute.rel("stylesheet"),
                  attribute.href(
                    "https://cdn.jsdelivr.net/gh/lustre-labs/ui/priv/styles.css",
                  ),
                ]),
                html.script(
                  [
                    attribute.type_("module"),
                    attribute.src("/lustre-server-component.mjs"),
                  ],
                  "",
                ),
              ]),
              html.body([], [
                server_component.component([server_component.route("/shinirc")]),
              ]),
            ])
            |> element.to_document_string_builder
            |> bytes_builder.from_string_builder
            |> mist.Bytes,
          )
      }
    }
    |> mist.new
    |> mist.port(3000)
    |> mist.start_http

  process.sleep_forever()
}

// 

type Shinirc =
  Subject(lustre.Action(mvu.Msg, lustre.ServerComponent))

fn socket_init(
  conn: WebsocketConnection,
) -> #(Shinirc, Option(Selector(lustre.Patch(mvu.Msg)))) {
  let app = mvu.app()
  let assert Ok(shinirc) = lustre.start_actor(app, 0)

  process.send(
    shinirc,
    server_component.subscribe("ws", fn(patch) {
      patch
      |> server_component.encode_patch
      |> json.to_string
      |> mist.send_text_frame(conn, _)

      Nil
    }),
  )

  #(shinirc, None)
}

fn socket_update(
  shinirc: Shinirc,
  _conn: WebsocketConnection,
  msg: WebsocketMessage(lustre.Patch(mvu.Msg)),
) {
  case msg {
    mist.Text(json) -> {
      let action = json.decode(json, server_component.decode_action)

      case action {
        Ok(action) -> process.send(shinirc, action)
        Error(_) -> Nil
      }

      actor.continue(shinirc)
    }

    mist.Binary(_) -> actor.continue(shinirc)
    mist.Custom(_) -> actor.continue(shinirc)
    mist.Closed | mist.Shutdown -> actor.Stop(process.Normal)
  }
}

fn socket_close(shinirc: Shinirc) {
  process.send(shinirc, lustre.shutdown())
}

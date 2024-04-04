import db
import mvu
import gleam/bytes_builder
import gleam/erlang
import gleam/erlang/process.{type Selector, type Subject}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/json
import gleam/list
import gleam/option.{type Option, None}
import gleam/otp/actor
import gleam/result
import gluid
import lustre
import lustre/attribute
import lustre/element
import lustre/element/html.{html}
import lustre/server_component
import mist.{
  type Connection, type ResponseData, type WebsocketConnection,
  type WebsocketMessage,
}

type SocketState {
  SocketState(
    messages: Subject(lustre.Action(mvu.Msg, lustre.ServerComponent)),
    id: String,
  )
}

pub fn main() {
  ["shinirc-1", "shinirc-2", "shinirc-3"]
  |> list.each(fn(channel) { db.create_table(channel) })

  let app = mvu.app()
  let assert Ok(shinirc) = lustre.start_actor(app, 0)

  let assert Ok(_) =
    fn(req: Request(Connection)) -> Response(ResponseData) {
      case request.path_segments(req) {
        ["shinirc"] ->
          mist.websocket(
            request: req,
            on_init: socket_init(_, shinirc),
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

        ["style.css"] -> {
          let assert Ok(priv) = erlang.priv_directory("shinirc")
          let path = priv <> "/static/style.css"

          mist.send_file(path, offset: 0, limit: None)
          |> result.map(fn(css) {
            response.new(200)
            |> response.prepend_header("content-type", "text/css")
            |> response.set_body(css)
          })
          |> result.lazy_unwrap(fn() {
            response.new(404)
            |> response.set_body(mist.Bytes(bytes_builder.new()))
          })
        }

        ["script.js"] -> {
          let assert Ok(priv) = erlang.priv_directory("shinirc")
          let path = priv <> "/static/script.js"

          mist.send_file(path, offset: 0, limit: None)
          |> result.map(fn(js) {
            response.new(200)
            |> response.prepend_header("content-type", "application/javascript")
            |> response.set_body(js)
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
                html.link([
                  attribute.rel("stylesheet"),
                  attribute.href("/style.css"),
                ]),
                html.script(
                  [
                    attribute.type_("module"),
                    attribute.src("/lustre-server-component.mjs"),
                  ],
                  "",
                ),
                html.script([attribute.src("/script.js")], ""),
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

fn socket_init(
  conn: WebsocketConnection,
  messages: Subject(lustre.Action(mvu.Msg, lustre.ServerComponent)),
) -> #(SocketState, Option(Selector(lustre.Patch(mvu.Msg)))) {
  let id = gluid.guidv4()

  process.send(
    messages,
    server_component.subscribe(id, fn(patch) {
      patch
      |> server_component.encode_patch
      |> json.to_string
      |> mist.send_text_frame(conn, _)

      Nil
    }),
  )

  #(SocketState(messages, id), None)
}

fn socket_update(
  state: SocketState,
  _conn: WebsocketConnection,
  msg: WebsocketMessage(lustre.Patch(mvu.Msg)),
) {
  case msg {
    mist.Text(json) -> {
      let action = json.decode(json, server_component.decode_action)

      case action {
        Ok(action) -> process.send(state.messages, action)
        Error(_) -> Nil
      }

      actor.continue(state)
    }

    mist.Binary(_) -> actor.continue(state)
    mist.Custom(_) -> actor.continue(state)
    mist.Closed | mist.Shutdown -> actor.Stop(process.Normal)
  }
}

fn socket_close(state: SocketState) {
  process.send(state.messages, server_component.unsubscribe(state.id))
}

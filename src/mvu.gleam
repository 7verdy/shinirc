import gleam/io
import gleam/list
import lustre
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import lustre/ui

// MAIN ------------------------------------------------------------------------

pub fn app() {
  lustre.application(init, update, view)
}

// MODEL -----------------------------------------------------------------------

pub opaque type Message {
  Message(username: String, message: String)
}

pub type Model {
  Model(username: String, message: String, messages: List(Message))
}

fn init(_) -> #(Model, Effect(Msg)) {
  #(Model("", "", []), effect.none())
}

// UPDATE ----------------------------------------------------------------------

pub opaque type Msg {
  Send
  UpdateUsername(String)
  UpdateMessage(String)
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    Send -> {
      #(
        Model(model.username, "", [
          Message(model.username, model.message),
          ..model.messages
        ]),
        effect.none(),
      )
    }
    UpdateUsername(username) -> #(
      Model(..model, username: username),
      effect.none(),
    )
    UpdateMessage(message) -> #(Model(..model, message: message), effect.none())
  }
}

// VIEW ------------------------------------------------------------------------

fn view(model: Model) -> Element(Msg) {
  let text_styles = [#("color", "white"), #("font-family", "Arial, sans-serif")]

  html.div([attribute.id("app")], [
    html.div([attribute.id("sidebar")], [
      html.div([attribute.id("title-desc")], [
        html.h1([attribute.style(text_styles)], [element.text("ShinIRC")]),
        html.p([attribute.style([#("text-align", "center")])], [
          element.text("A simple chat app made with Lustre"),
        ]),
      ]),
    ]),
    html.div([attribute.id("chat")], [
      html.div([attribute.id("channel-messages")], [
        case model.messages {
          [] ->
            html.p([attribute.style(text_styles)], [
              element.text("No messages yet"),
            ])
          _ -> {
            html.ul(
              [],
              model.messages
                |> list.map(fn(message) {
                  html.li([], [
                    element.text(message.username <> ": " <> message.message),
                  ])
                }),
            )
          }
        },
      ]),
      html.div([attribute.id("message-form")], [
        ui.input([
          attribute.id("username-input"),
          attribute.value(model.username),
          attribute.placeholder("Type your username..."),
          event.on_input(UpdateUsername),
        ]),
        ui.input([
          attribute.id("message-input"),
          attribute.value(model.message),
          attribute.placeholder("Type a message..."),
          event.on_input(UpdateMessage),
        ]),
        ui.button([attribute.id("send-button"), event.on_click(Send)], [
          element.text("Send"),
        ]),
      ]),
    ]),
  ])
}

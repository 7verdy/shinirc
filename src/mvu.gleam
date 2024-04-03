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
  Model(current_message: Message, messages: List(Message))
}

fn init(_) -> #(Model, Effect(Msg)) {
  #(Model(Message("lustre", "Hello, world!"), []), effect.none())
}

// UPDATE ----------------------------------------------------------------------

pub opaque type Msg {
  Send(username: String, message: String)
  UpdateUsername(String)
  UpdateMessage(String)
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    Send(username, message) -> #(
      Model(Message(username, message), [
        Message(username, message),
        ..model.messages
      ]),
      effect.none(),
    )
    UpdateUsername(username) -> #(
      Model(Message(username, model.current_message.message), model.messages),
      effect.none(),
    )
    UpdateMessage(message) -> #(
      Model(Message(model.current_message.username, message), model.messages),
      effect.none(),
    )
  }
}

// VIEW ------------------------------------------------------------------------

fn view(model: Model) -> Element(Msg) {
  let text_styles = [#("color", "white"), #("font-family", "Arial, sans-serif")]

  let current_message = model.current_message
  let username = current_message.username

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
          attribute.id("username"),
          attribute.value(username),
          attribute.placeholder("Type your username..."),
          event.on_input(UpdateUsername),
        ]),
        ui.input([
          attribute.id("message"),
          attribute.value(model.current_message.message),
          attribute.placeholder("Type a message..."),
          event.on_input(UpdateMessage),
        ]),
        ui.button(
          [
            attribute.style([
              #("background-color", "#5c61ed"),
              #("color", "white"),
              #("padding", "0.5rem 1rem"),
              #("border", "none"),
              #("border-radius", "0.25rem"),
              #("margin-left", "0.5rem"),
            ]),
            event.on_click(Send(username, model.current_message.message)),
          ],
          [element.text("Send")],
        ),
      ]),
    ]),
  ])
}

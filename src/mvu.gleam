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
  let styles = [#("width", "100vw"), #("height", "100vh"), #("padding", "1rem")]
  let current_message = model.current_message
  let username = current_message.username

  html.div([attribute.style(styles)], [
    html.h1([], [element.text("ShinIRC")]),
    html.p([], [element.text("A simple chat app made with Lustre")]),
    html.div([], [element.text("Messages")]),
    case model.messages {
      [] -> html.p([], [element.text("No messages yet")])
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
    html.div([], [element.text("Send a message")]),
    ui.input([attribute.value(username), event.on_input(UpdateUsername)]),
    ui.input([
      attribute.value(model.current_message.message),
      event.on_input(UpdateMessage),
    ]),
    ui.button([event.on_click(Send(username, model.current_message.message))], [
      element.text("Send"),
    ]),
  ])
}

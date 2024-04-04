import birl
import birl/duration
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
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
  Message(username: String, message: String, timestamp: String, channel: String)
}

pub type Model {
  Model(
    username: String,
    message: String,
    timestamp: String,
    channel: String,
    messages: List(Message),
  )
}

fn init(_) -> #(Model, Effect(Msg)) {
  #(Model("", "", "", "shinirc-1", []), effect.none())
}

// UPDATE ----------------------------------------------------------------------

pub opaque type Msg {
  Send
  UpdateUsername(String)
  UpdateMessage(String)
  UpdateChannel(String)
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    Send -> {
      #(
        Model(model.username, "", "", model.channel, [
          Message(
            model.username,
            model.message,
            birl.to_time_string(birl.now()),
            model.channel,
          ),
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
    UpdateChannel(channel) -> #(Model(..model, channel: channel), effect.none())
  }
}

// UTILS -----------------------------------------------------------------------

fn time_beautifier(time: String) -> String {
  let splits =
    time
    |> string.split(":")
    |> list.map(fn(x) { result.unwrap(int.parse(x), 0) })
  let hours = result.unwrap(list.at(splits, 0), 0)
  let minutes = result.unwrap(list.at(splits, 1), 0)

  let now = birl.to_time_string(birl.now())
  let now_splits =
    now
    |> string.split(":")
    |> list.map(fn(x) { result.unwrap(int.parse(x), 0) })
  let now_hours = result.unwrap(list.at(now_splits, 0), 0)
  let now_minutes = result.unwrap(list.at(now_splits, 1), 0)

  case hours {
    hour if now_hours < hour -> "Yesterday at " <> time
    hour if now_hours == hour -> {
      case minutes {
        minute if now_minutes < minute ->
          "Yesterday at "
          <> int.to_string(hours)
          <> ":"
          <> int.to_string(minutes)
        minute if now_minutes == minute ->
          "Today at " <> int.to_string(hours) <> ":" <> int.to_string(minutes)
        _ ->
          "Today at " <> int.to_string(hours) <> ":" <> int.to_string(minutes)
      }
    }
    _ -> "Today at " <> int.to_string(hours) <> ":" <> int.to_string(minutes)
  }
}

// VIEW ------------------------------------------------------------------------

fn view(model: Model) -> Element(Msg) {
  let text_styles = [#("color", "white"), #("font-family", "Arial, sans-serif")]
  let channel_list = ["shinirc-1", "shinirc-2", "shinirc-3"]

  html.div([attribute.id("app")], [
    html.div([attribute.id("sidebar")], [
      html.div([attribute.id("title-desc")], [
        html.h1([attribute.style(text_styles)], [element.text("ShinIRC")]),
        html.p([attribute.style([#("text-align", "center")])], [
          element.text("A simple chat app made with Lustre"),
        ]),
      ]),
      html.div([attribute.id("channel-list")], [
        html.ul(
          [],
          channel_list
            |> list.map(fn(channel) {
              html.li([], [
                ui.button([event.on_click(UpdateChannel(channel))], [
                  element.text(channel),
                ]),
              ])
            }),
        ),
      ]),
    ]),
    html.div([attribute.id("chat")], [
      html.div([attribute.id("channel-title")], [
        html.h2([attribute.style(text_styles)], [element.text(model.channel)]),
      ]),
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
                    element.text(
                      time_beautifier(message.timestamp)
                      <> " | "
                      <> message.username
                      <> ": "
                      <> message.message,
                    ),
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

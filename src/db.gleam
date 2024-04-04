import gleam/dynamic
import sqlight

pub fn create_table(channel: String) {
  use conn <- sqlight.with_connection("data.db")
  let sql = "
        create table if not exists " <> channel <> " (
            username text not null,
            message text not null,
            timestamp integer not null
        );
    "

  let assert Ok(Nil) = sqlight.exec(sql, conn)
  Nil
}

pub fn send_data(channel: String, message: #(String, String, String)) {
  use conn <- sqlight.with_connection("data.db")
  let sql = "
        insert into " <> channel <> " (username, message, timestamp)
        values ('" <> message.0 <> "', '" <> message.1 <> "', " <> message.2 <> ");
    "

  let assert Ok(Nil) = sqlight.exec(sql, conn)
  Nil
}

pub fn get_data(channel: String) -> List(#(String, String, String)) {
  use conn <- sqlight.with_connection("data.db")
  let message_decoder =
    dynamic.tuple3(dynamic.string, dynamic.string, dynamic.string)

  let sql = "select * from " <> channel <> ";"
  let assert Ok(messages) = sqlight.query(sql, conn, [], message_decoder)

  messages
}

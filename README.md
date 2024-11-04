# **notify-send-rs**

Rust version of notify-send for display notifications on the linux desktop using [notify-rust](https://docs.rs/notify-rust/)

## To get started:
* **Download the latest revision**
```
git clone https://github.com/VHSgunzo/notify-send-rs.git && cd notify-send-rs
```

* **Compile a binary**
```
rustup default nightly
rustup target add x86_64-unknown-linux-musl
rustup component add rust-src --toolchain nightly
cargo build --release
```
* Or take an already precompiled binary file from the [releases](https://github.com/VHSgunzo/notify-send-rs/releases)

## Usage:
```
notify-send-rs [OPTIONS] <TITLE> [ARGS]

ARGS:
<TITLE>    Title of the Notification
<BODY>     Message body
<ID>       Specifies the ID and overrides existing notifications with the same ID

OPTIONS:
-a, --app-name <APP_NAME>          Specifies the app name
-c, --categories <CATEGORIES>      Specifies the notification category
-d, --debug                        Shows information about the running notification server and prints notification to stdout
-h, --help                         Print help information
--hint <HINT>                      Specifies basic extra data to pass. Valid types are int, double, string and byte. Pattern: TYPE:NAME:VALUE
-i, --icon <ICON>                  Specifies an icon filename to display
-t, --expire-time <EXPIRE_TIME>    Specifies the timeout in milliseconds at which to expire the notification
-u, --urgency <URGENCY>            Specifies the urgency level [possible values: low, normal, critical]
-V, --version                      Print version information
```

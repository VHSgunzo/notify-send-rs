use clap::Parser;
use clap::ArgEnum;
use notify_rust::Hint;
use notify_rust::Urgency;
use notify_rust::Notification;
use notify_rust::error::Result as nResult;

#[derive(ArgEnum, Clone, Copy)]
pub enum UrgencyShim {
    Low,
    Normal,
    Critical,
}

impl From<UrgencyShim> for Urgency {
    fn from(urgency: UrgencyShim) -> Urgency {
        match urgency {
            UrgencyShim::Low => Urgency::Low,
            UrgencyShim::Normal => Urgency::Normal,
            UrgencyShim::Critical => Urgency::Critical,
        }
    }
}

fn parse_hint(pattern: &str) -> Result<Hint, String> {
    let parts = pattern.split(':').collect::<Vec<&str>>();
    if parts.len() != 3 {
        return Err("Wrong number of segments".into());
    }
    let (_typ, name, value) = (parts[0], parts[1], parts[2]);
    Hint::from_key_val(name, value)
}

#[derive(Parser)]
#[clap(author, version, about)]
struct Cli {
    /// Title of the Notification
    title: String,
    /// Message body
    body: Option<String>,
    /// Specifies the app name
    #[clap(short, long)]
    app_name: Option<String>,
    #[clap(flatten)]
    cli_args: CliArgs,
}

#[derive(clap::Args)]
struct CliArgs {
    /// Specifies the timeout in milliseconds at which to expire the notification
    #[clap(short = 't', long)]
    expire_time: Option<i32>,
    /// Specifies an icon filename to display
    #[clap(short = 'i', long)]
    icon: Option<std::path::PathBuf>,
    /// Specifies the ID and overrides existing notifications with the same ID
    id: Option<u32>,
    /// Specifies the notification category
    #[clap(short, long)]
    categories: Option<Vec<String>>,
    /// Specifies basic extra data to pass. Valid types are int, double, string and byte. Pattern: TYPE:NAME:VALUE
    #[clap(long, parse(try_from_str = parse_hint))]
    hint: Option<Hint>,
    /// Specifies the urgency level
    #[clap(short, long, arg_enum)]
    urgency: Option<UrgencyShim>,
    /// Shows information about the running notification server and prints notification to stdout
    #[clap(short, long)]
    debug: bool,
}

fn main() -> nResult<()> {
    let args = Cli::parse();

    let title = args.title;
    let body = args.body;
    let app_name = args.app_name;
    let cli_args = args.cli_args;

    let mut notification = Notification::new();

    notification.summary(&title);

    if let Some(body) = body {
        notification.body(&body);
    }

    if let Some(appname) = app_name {
        notification.appname(&appname);
    }

    let CliArgs {
        expire_time,
        icon,
        id,
        categories,
        hint,
        urgency,
        debug,
    } = cli_args;
    if let Some(id) = id {
        notification.id(id);
    }

    if let Some(icon) = icon {
        notification.icon(icon.to_str().expect("Icon path is not valid unicode"));
    }

    if let Some(timeout) = expire_time {
        notification.timeout(timeout);
    }

    if let Some(urgency) = urgency {
        notification.urgency(urgency.into());
    }

    if let Some(hint) = hint {
        notification.hint(hint);
    }

    if let Some(categories) = categories {
        for category in categories {
            notification.hint(Hint::Category(category));
        }
    }

    if debug {
        let info = notify_rust::get_server_information()?;
        println!("server information:\n {:?}\n", info);

        let caps = notify_rust::get_capabilities()?;
        println!("capabilities:\n {:?}\n", caps);
        #[allow(deprecated)]
        notification.show_debug()
    } else {
        notification.show()
    }
    .map(|_| ())
}

use clap::Parser;
use std::{
    fs,
    io::{
        Error,
        ErrorKind,
    },
    path::PathBuf,
    process::{
        Command,
        ExitStatus,
    },
    sync::{
        atomic::{
            AtomicBool,
            Ordering,
        },
        Arc,
    },
    thread,
    time::Duration,
};

mod pg;

#[derive(Parser, Debug)]
#[command(author, version, about, long_about = None)]
struct Args {
    /// Ink! verifier image tag
    #[arg(short, long, default_value = "latest")]
    tag: String,

    /// Source directory, can be relative; e.g. '.'
    #[arg(required = true, value_parser)]
    source: PathBuf,

    /// Container engine
    #[arg(long, default_value = "docker")]
    engine: String,

    /// Environment file
    #[arg(long)]
    env_file: Option<String>,
}

/// Executes the contract build process.
///
/// This function will spawn a guarded child process for docker.
/// It requires the docker command to be installed in the system.
fn exec_build(args: Args) -> Result<ExitStatus, Error> {
    let tag = args.tag;
    let path: PathBuf = args.source;

    assert!(path.exists());

    let build_dir = fs::canonicalize(&path)?
        .into_os_string()
        .into_string()
        .unwrap();

    let running = Arc::new(AtomicBool::new(true));
    let r = running.clone();

    ctrlc::set_handler(move || {
        r.store(false, Ordering::SeqCst);
    })
    .expect("Error setting Ctrl-C handler");

    let build_vol = &format!("{build_dir}:/build");
    let image = &format!("ink-verifier:{tag}");

    let mut cmd_args = vec![
        "run",
        "--entrypoint",
        "package-contract",
        "-v",
        build_vol,
        "--rm",
    ];

    if let Some(env_file) = args.env_file.as_ref() {
        cmd_args.push("--env-file");
        cmd_args.push(env_file)
    }

    cmd_args.push(image);

    println!("Building package w/ args: {:?}", cmd_args);

    let mut pg = pg::ProcessGuard::spawn(Command::new(args.engine).args(cmd_args))?;

    while running.load(Ordering::SeqCst) {
        match pg.try_wait()? {
            Some(status) => return Ok(status),
            // Busy wait :/
            None => thread::sleep(Duration::from_millis(400)),
        }
    }

    Err(Error::new(ErrorKind::Interrupted, "Interrupted"))
}

fn main() -> Result<(), Error> {
    let args = Args::parse();
    let status = exec_build(args)?;

    match status.code() {
        Some(code) => std::process::exit(code),
        None => std::process::exit(2),
    }
}

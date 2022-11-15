use clap::Parser;
use std::{
    fs,
    io::Error,
    path::PathBuf,
    process::{
        Command,
        ExitStatus,
    },
};

#[derive(Parser, Debug)]
#[command(author, version, about, long_about = None)]
struct Args {
    /// Ink! verifier image name
    #[arg(short, long, default_value = "ink-verifier")]
    image: String,

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
    let image = args.image;
    let path: PathBuf = args.source;

    assert!(path.exists());

    let build_dir = fs::canonicalize(&path)?
        .into_os_string()
        .into_string()
        .unwrap();

    let build_vol = &format!("{build_dir}:/build");
    let image = &format!("{image}:{tag}");

    let mut cmd_args = vec![
        "run",
        "-i", // Keep STDIN open even if not attached
        "-t", // Allocate a pseudo-tty
        "--rm",
        "--entrypoint",
        "package-contract",
        "-v",
        build_vol,
    ];

    if let Some(env_file) = args.env_file.as_ref() {
        cmd_args.push("--env-file");
        cmd_args.push(env_file)
    }

    cmd_args.push(image);

    println!("Building package w/ args: {:?}", cmd_args);

    // Leverage on Docker attached STDIN pseudo-TTY
    return Command::new(args.engine).args(cmd_args).spawn()?.wait()
}

fn main() -> Result<(), Error> {
    let args = Args::parse();
    let status = exec_build(args)?;

    match status.code() {
        Some(code) => std::process::exit(code),
        None => std::process::exit(2),
    }
}

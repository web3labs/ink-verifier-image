//! Simple process guard to kill it when goes out of scope.

use std::{
    io,
    process::{
        Child,
        Command,
        ExitStatus,
    },
};

#[derive(Debug)]
pub struct ProcessGuard {
    child: Child,
}

impl ProcessGuard {
    fn new(child: Child) -> ProcessGuard {
        ProcessGuard { child }
    }

    pub fn spawn(cmd: &mut Command) -> io::Result<ProcessGuard> {
        match cmd.spawn() {
            Ok(child) => Ok(Self::new(child)),
            Err(e) => {
                if e.kind() == io::ErrorKind::NotFound {
                    eprintln!("Program {:?} not found.", cmd.get_program())
                }
                Err(e)
            }
        }
    }

    pub fn try_wait(&mut self) -> Result<Option<ExitStatus>, io::Error> {
        self.child.try_wait()
    }

    fn shutdown(&mut self) -> io::Result<Option<ExitStatus>> {
        match self.child.try_wait()? {
            None => {
                self.child.kill()?;
            }
            Some(status) => return Ok(Some(status)),
        }

        Ok(Some(self.child.wait()?))
    }
}

impl Drop for ProcessGuard {
    #[inline]
    fn drop(&mut self) {
        let pid = self.child.id();

        if let Err(e) = self.shutdown() {
            eprintln!("Could not cleanly kill PID {}: {:?}", pid, e);
        }
    }
}

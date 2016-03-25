# C bindings for Crystal

Follows the IEEE Std 1003.1, 2013 Edition (The Open Group Base Specifications
Issue 7) as much as libc implementations do.

Bindings are automatically generated with CrystalLib from C headers.


## Targets

Crystal only supports the `x86` and `x86_64` targets for now, but we should be
capable to generate bindings for whatever POSIX C implementation. Each target
will be checked when headers have been verified to be compliant.

- Android
  - [ ] `arm`
  - [ ] `arm64`
  - [ ] `mips`
  - [ ] `mips64`
  - [ ] `mips`
  - [ ] `mips64`
  - [ ] `x86`
  - [ ] `x86_64`

- FreeBSD
  - [ ] `x86`
  - [ ] `x86_64`

- iOS
  - [ ] `arm`
  - [ ] `arm64`

- Linux
  - [ ] gnu (`x86`, `x86_64`)
  - [ ] musl (`x86`, `x86_64`)

- Mac OSX
  - [ ] darwin (`x86_64`)

- Windows
  - [ ] cygwin

## Headers

- [ ] `aio.h`
- [x] `arpa/inet.h`
- [ ] `assert.h`
- [ ] `complex.h`
- [x] `cpio.h`
- [ ] `ctype.h`
- [x] `dirent.h`
- [x] `dlfcn.h`
- [x] `errno.h`
- [x] `fcntl.h`
- [x] `fenv.h`
- [x] `float.h`
- [ ] `fmtmsg.h`
- [x] `fnmatch.h`
- [x] `ftw.h`
- [x] `glob.h`
- [x] `grp.h`
- [x] `iconv.h`
- [ ] `inttypes.h`
- [ ] `iso646.h`
- [x] `langinfo.h`
- [x] `libgen.h`
- [x] `limits.h`
- [x] `locale.h`
- [x] `math.h`
- [x] `monetary.h`
- [ ] `mqueue.h`
- [ ] `ndbm.h`
- [x] `net/if.h`
- [x] `netdb.h`
- [x] `netinet/in.h`
- [x] `netinet/tcp.h`
- [x] `nl_types.h`
- [x] `poll.h`
- [x] `pthread.h`
- [x] `pwd.h`
- [x] `regex.h`
- [x] `sched.h`
- [x] `search.h`
- [x] `semaphore.h`
- [x] `setjmp.h`
- [x] `signal.h`
- [x] `spawn.h`
- [ ] `stdarg.h`
- [ ] `stdbool.h`
- [x] `stddef.h`
- [x] `stdint.h`
- [x] `stdio.h`
- [x] `stdlib.h`
- [x] `string.h`
- [x] `strings.h`
- [ ] `stropts.h`
- [x] `sys/ipc.h`
- [x] `sys/mman.h`
- [ ] `sys/msg.h`
- [x] `sys/resource.h`
- [x] `sys/select.h`
- [x] `sys/sem.h`
- [x] `sys/shm.h`
- [x] `sys/socket.h`
- [x] `sys/stat.h`
- [ ] `sys/statvfs.h`
- [x] `sys/time.h`
- [x] `sys/times.h`
- [x] `sys/types.h`
- [x] `sys/uio.h`
- [x] `sys/un.h`
- [x] `sys/utsname.h`
- [x] `sys/wait.h`
- [x] `syslog.h`
- [ ] `tar.h`
- [ ] `termios.h`
- [ ] `tgmath.h`
- [x] `time.h`
- [ ] `trace.h`
- [x] `ulimit.h`
- [x] `unistd.h`
- [x] `utmpx.h`
- [ ] `wchar.h`
- [ ] `wctype.h`
- [ ] `wordexp.h`


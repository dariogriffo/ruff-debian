# ruff-debian

Debian and Ubuntu packaging for [Ruff](https://docs.astral.sh/ruff/) — an
extremely fast Python linter and code formatter, written in Rust by Astral.

Packages are built automatically from official upstream releases (usually
within hours) and served from **[deb.griffo.io](https://deb.griffo.io)** for
Debian (bookworm, trixie, forky, sid) and Ubuntu (jammy, noble, questing,
resolute) on amd64, arm64, armel, armhf, ppc64el, s390x, riscv64 and i386.

## Install

> ⚠️ **From 1 October 2026, apt access requires a yearly subscription**
> ([deb.griffo.io](https://deb.griffo.io)). To use this tool for free, download
> the .deb from the [Releases](https://github.com/dariogriffo/ruff-debian/releases) page
> and install it manually (see below).

```bash
sudo install -d -m 0755 /etc/apt/keyrings
curl -fsSL https://deb.griffo.io/EA0F721D231FDD3A0A17B9AC7808B4DD62C41256.asc | sudo gpg --dearmor --yes -o /etc/apt/keyrings/deb.griffo.io.gpg
echo "deb [signed-by=/etc/apt/keyrings/deb.griffo.io.gpg] https://deb.griffo.io/apt $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/deb.griffo.io.list > /dev/null
sudo apt update
sudo apt install -y ruff
```

### Manual Installation

1. Download the .deb package for your Debian version available on
   the [Releases](https://github.com/dariogriffo/ruff-debian/releases) page.
2. Install the downloaded .deb package.

```sh
sudo dpkg -i <filename>.deb
```

## How it works

- `check-upstream.yml` polls upstream hourly; a new release dispatches `release.yml`.
- `release.yml` builds binary packages (Docker, per suite × architecture, from the
  upstream musl/gnu tarballs) and source packages (`.dsc`), then publishes a GitHub
  release tagged `<version>+<build>`.
- The deb.griffo.io mirror ingests published releases automatically.

Manual build: `./build.sh <version> <build> [arch|all]` (e.g. `./build.sh 0.15.21 1 all`).

## Links

- Upstream: https://github.com/astral-sh/ruff
- Site page: https://deb.griffo.io/install-latest-ruff-in-debian.html
- Repository: https://deb.griffo.io

#!/bin/bash
#
# Shared helpers for the nextcloud-spreed-signaling scripts.
# Source this file; do not execute it.

#=== strip_ansi ===
#
# Echoes stdin with terminal escape sequences removed, so string length
# reflects what is actually visible. Handles both CSI sequences (colour, e.g.
# \033[32m) and charset designations (e.g. \033(B), which "tput sgr0" emits on
# xterm alongside \033[m.
strip_ansi() {
  sed -e $'s/\033\[[0-9;]*[a-zA-Z]//g' -e $'s/\033[()][A-Za-z0-9]//g'
}

#=== banner ===
#
# Draws a box around stdin, replacing the "boxes" utility. boxes was previously
# required but is not packaged consistently: it needs EPEL on RHEL derivatives
# and is not packaged for Alpine at all. It was only ever used for cosmetic
# output, so a shell function removes the dependency entirely.
#
# Handles multi-line input and ignores escape sequences when measuring width, so
# coloured text stays aligned (which boxes itself did not manage).
#
# Usage: echo "text" | banner
banner() {
  local line plain sub width=0 max
  local -a lines=()

  # Keep the box within the terminal. The border and padding consume 6
  # columns. Falls back to 80 when the width cannot be determined, e.g. when
  # output is piped or redirected to a log.
  max=$(tput cols 2>/dev/null)
  case $max in ''|*[!0-9]*) max=80 ;; esac
  max=$((max - 6))
  [ $max -lt 20 ] && max=20

  while IFS= read -r line || [ -n "$line" ]; do
    plain=$(printf '%s' "$line" | strip_ansi)

    # Wrap anything too wide, preferring to break at spaces. Without this a
    # long value such as a log path produces a box wider than the terminal,
    # which the terminal then wraps and the borders appear ragged.
    if [ ${#plain} -gt $max ]; then
      while IFS= read -r sub; do
        lines+=("$sub")
        plain=$(printf '%s' "$sub" | strip_ansi)
        [ ${#plain} -gt $width ] && width=${#plain}
      done < <(printf '%s\n' "$line" | fold -s -w $max)
    else
      lines+=("$line")
      [ ${#plain} -gt $width ] && width=${#plain}
    fi
  done

  local border
  border=$(printf '%*s' $((width + 4)) '')
  border=${border// /-}

  printf '+%s+\n' "$border"
  printf '|%*s|\n' $((width + 4)) ''
  for line in "${lines[@]}"; do
    plain=$(printf '%s' "$line" | strip_ansi)
    printf '|  %s%*s  |\n' "$line" $((width - ${#plain})) ''
  done
  printf '|%*s|\n' $((width + 4)) ''
  printf '+%s+\n' "$border"
}

#=== resolve_fqdn <hostname> ===
#
# Echoes the first IPv4 address a hostname resolves to, or nothing.
#
# Prefers getent, which uses glibc NSS and is always present. dig and host come
# from packages named differently per distribution (dnsutils, bind-utils) and
# are frequently not installed, so they are only fallbacks.
resolve_fqdn() {
  local fqdn=$1 ip=""

  if command -v getent > /dev/null 2>&1; then
     ip=$(getent ahostsv4 "$fqdn" 2>/dev/null | awk '{print $1; exit}')
  fi

  if [ -z "$ip" ] && command -v dig > /dev/null 2>&1; then
     ip=$(dig +short A "$fqdn" 2>/dev/null | grep -E '^[0-9]+(\.[0-9]+){3}$' | head -1)
  fi

  if [ -z "$ip" ] && command -v host > /dev/null 2>&1; then
     ip=$(host -t A "$fqdn" 2>/dev/null | awk '/has address/ {print $4; exit}')
  fi

  printf '%s' "$ip"
}

#=== certbot_account_args ===
#
# Collects Lets Encrypt account details and echoes the corresponding certbot
# flags on stdout. Prompts go to stderr so the caller can capture the result
# with $(...).
#
# Certbot runs here through "docker run" with no TTY and no stdin, so it cannot
# prompt for the terms of service or an email address itself. It reports
# "Skipped user interaction because Certbot doesn't appear to be running in a
# terminal" and then aborts with EOFError. Gathering the answers here and
# passing --non-interactive makes the outcome the same on every run instead of
# depending on whether an account already happens to exist.
#
# Returns 1 if the terms of service are declined.
certbot_account_args() {
  local email agree

  echo "" >&2
  echo "Lets Encrypt requires an account. The registration is stored under" >&2
  echo "$BASE/certbot/conf/accounts and is reused for renewals." >&2
  echo "" >&2
  echo "The Lets Encrypt Terms of Service are published at:" >&2
  echo "  https://letsencrypt.org/repository/" >&2
  echo "" >&2

  read -p "Do you agree to the Lets Encrypt Terms of Service? [y/N]: " agree
  case "$agree" in
    [Yy]*) ;;
    *)
      echo "" >&2
      echo "${RED}You must agree to the Terms of Service to obtain a certificate. ${RESET}" >&2
      return 1
      ;;
  esac

  read -p "Enter an email address for expiry notices (leave empty for none): " email

  if [ -n "$email" ]; then
     printf -- '--non-interactive --agree-tos --email %s' "$email"
  else
     echo "${RED}Registering without an email address. You will not be warned before expiry. ${RESET}" >&2
     printf -- '--non-interactive --agree-tos --register-unsafely-without-email'
  fi
}

#=== set_colours ===
#
# Sets RED/GREEN/RESET, empty if the output is not a terminal or tput is
# unavailable. Previously the scripts called tput unconditionally, which emits
# "No value for $TERM" warnings when run from cron or through a pipe, and made
# ncurses a hard dependency.
set_colours() {
  if [ -t 1 ] && command -v tput > /dev/null 2>&1 && [ -n "${TERM:-}" ]; then
     RED=$(tput setaf 1 2>/dev/null)
     GREEN=$(tput setaf 2 2>/dev/null)
     RESET=$(tput sgr0 2>/dev/null)
  else
     RED=""
     GREEN=""
     RESET=""
  fi
}

#=== detect_pkg_manager ===
#
# Sets PKG_INSTALL to a command that installs a package non-interactively, and
# PKG_UPDATE to the metadata refresh command (empty where not needed).
# Returns 1 if no supported package manager is present.
#
# The packages this repository needs (git, curl, openssl) are named identically
# on every distribution below, so no per-distro name mapping is required.
detect_pkg_manager() {
  if command -v apt-get > /dev/null 2>&1; then
    PKG_UPDATE="apt-get update"
    PKG_INSTALL="apt-get install -y"
  elif command -v dnf > /dev/null 2>&1; then
    PKG_UPDATE=""
    PKG_INSTALL="dnf install -y"
  elif command -v yum > /dev/null 2>&1; then
    PKG_UPDATE=""
    PKG_INSTALL="yum install -y"
  elif command -v zypper > /dev/null 2>&1; then
    PKG_UPDATE="zypper --non-interactive refresh"
    PKG_INSTALL="zypper --non-interactive install"
  elif command -v pacman > /dev/null 2>&1; then
    PKG_UPDATE=""
    PKG_INSTALL="pacman -S --noconfirm --needed"
  elif command -v apk > /dev/null 2>&1; then
    PKG_UPDATE="apk update"
    PKG_INSTALL="apk add"
  else
    PKG_UPDATE=""
    PKG_INSTALL=""
    return 1
  fi
  return 0
}

#=== check_prereq <command> <package name> ===
#
# Uses the command if it is already installed. Otherwise installs it with the
# detected package manager, or exits with an actionable message if there is
# none. Package metadata is refreshed at most once per run.
check_prereq() {
  local cmd=$1
  local pkg=$2

  if command -v "$cmd" > /dev/null 2>&1; then
     echo "${GREEN}$cmd Exists! Proceeding... ${RESET}"
     return 0
  fi

  if ! detect_pkg_manager; then
     echo "${RED}$cmd is required but is not installed, and no supported package manager was found. Please install $pkg and run this script again. Exiting... ${RESET}"
     exit 1
  fi

  if [ -n "$PKG_UPDATE" ] && [ "${PKG_METADATA_REFRESHED:-0}" -eq 0 ]; then
     echo "Refreshing package metadata"
     $PKG_UPDATE > /dev/null 2>&1
     PKG_METADATA_REFRESHED=1
  fi

  echo "Installing $pkg"
  $PKG_INSTALL "$pkg" > /dev/null 2>&1

  if ! command -v "$cmd" > /dev/null 2>&1; then
     echo "${RED}Failed to install $pkg with \"$PKG_INSTALL\". Please install it manually and run this script again. Exiting... ${RESET}"
     exit 1
  fi

  echo "${GREEN}Done ${RESET}"
}

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

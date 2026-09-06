#!/usr/bin/env bash
set -e

c3c build game-linux
mv build/game.so build/game_ready.so

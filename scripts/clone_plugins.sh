#!/bin/bash

mkdir -p plugins/kalitools
cd plugins

# First set of repos (no prefix)
git clone https://github.com/tinyhumansai/openhuman
git clone https://github.com/mempalace/mempalace
git clone https://github.com/h4ckf0r0day/obscura
git clone https://github.com/CursorTouch/Windows-MCP
git clone https://github.com/alexzhang13/rlm
git clone https://github.com/trycua/cua
git clone https://github.com/trailofbits/skills
git clone https://github.com/NVlabs/parrot
git clone https://github.com/bahdotsh/wrkflw
git clone https://github.com/kunchenguid/no-mistakes
git clone https://github.com/huggingface/ml-intern
git clone https://github.com/bradwmorris/ra-h_os
git clone https://github.com/Luce-Org/lucebox-hub
git clone https://github.com/anakin87/llm-rl-environments-lil-course
git clone https://github.com/bytedance/DanceUI
git clone https://github.com/abhigyanpatwari/GitNexus
git clone https://github.com/datawhalechina/easy-vibe
git clone https://github.com/kyegomez/OpenMythos
git clone https://github.com/PurpleAILAB/Decepticon
git clone https://github.com/z4nzu/hackingtool
git clone https://github.com/garrytan/gstack
git clone https://github.com/1jehuang/jcode

# Second set of repos (prefix with kali_)
git clone https://github.com/lyogavin/airllm kali_airllm
git clone https://github.com/PurpleDoubleD/locally-uncensored kali_locally-uncensored
git clone https://github.com/Aider-AI/aider kali_aider
git clone https://github.com/BerriAI/litellm kali_litellm
git clone https://github.com/microsoft/BitNet kali_BitNet
git clone https://github.com/ethanplusai/jarvis kali_jarvis
git clone https://github.com/KeygraphHQ/shannon kali_shannon
git clone https://github.com/Conway-Research/automaton kali_automaton
git clone https://github.com/safishamsi/graphify kali_graphify
git clone https://github.com/gsd-build/get-shit-done kali_get-shit-done
git clone https://github.com/snarktank/ralph kali_ralph
git clone https://github.com/openclaw/openclaw.git kali_openclaw

cd ..

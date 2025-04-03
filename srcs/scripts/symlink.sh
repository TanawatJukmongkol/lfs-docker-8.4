#!/bin/bash

# Link bashrc and bash_profile
ln -s  /home/lfs/srcs/.bash_profile /home/lfs/.bash_profile
ln -s  /home/lfs/srcs/.bashrc       /home/lfs/.bashrc

# Link all directory in /persist
LINKED_FROM="$(find /persist -mindepth 1 -type d)"
LINKED_TO="$(<<< "$LINKED_FROM" sed -n -e 's/^\/persist//p' | tr '\n' ' ')"

from_array=(`echo $LINKED_FROM`)
to_array=(`echo $LINKED_TO`)

# Iterate over the arrays and create symbolic links
for i in "${!from_array[@]}"; do
  if [ -d "${to_array[$i]}" ]; then continue; fi
  # echo ln -s "${from_array[$i]}" "${to_array[$i]}"
  ln -s "${from_array[$i]}" "${to_array[$i]}"
  chown -h lfs:lfs "${to_array[$i]}"
done

# Link all files in /persist
LINKED_FROM="$(find /persist -mindepth 1 -type f)"
LINKED_TO="$(<<< "$LINKED_FROM" sed -n -e 's/^\/persist//p' | tr '\n' ' ')"

from_array=(`echo $LINKED_FROM`)
to_array=(`echo $LINKED_TO`)

# Iterate over the arrays and create symbolic links
for i in "${!from_array[@]}"; do
  if [ -f "${to_array[$i]}" ]; then continue; fi
  # echo ln -s "${from_array[$i]}" "${to_array[$i]}"
  ln -s "${from_array[$i]}" "${to_array[$i]}"
  chown -h lfs:lfs "${to_array[$i]}"
done

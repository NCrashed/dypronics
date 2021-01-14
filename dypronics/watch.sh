clear
dub test
inotifywait -q -m -e close_write source dub.json |
while read -r filename event; do
  clear
  dub test
done

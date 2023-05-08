Compress-Archive ../export/webxr/* package.zip -Force
scp package.zip seminar.jirovcovka.net:~/puzzle_prism/package.zip
ssh seminar.jirovcovka.net "~/puzzle_prism/recv.sh"
Remove-Item package.zip
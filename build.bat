nasm -f win64 display.asm
nasm -f win64 game.asm
nasm -f win64 input.asm
ld -o snake.exe -s display.obj game.obj input.obj opengl32.dll glut32.dll kernel32.dll user32.dll
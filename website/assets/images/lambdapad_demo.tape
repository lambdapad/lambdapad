Output lambdapad_demo.gif

Require lpad
Require curl

Set Shell "zsh"
Set FontSize 15
Set Width 1100
Set Height 680
Set Padding 20
Set Theme "Catppuccin Mocha"
Set TypingSpeed 45ms

Hide
Type "cd $(mktemp -d)"
Enter
Sleep 300ms
Type "clear"
Enter
Sleep 300ms
Show

Type "lpad new my-blog"
Enter
Sleep 2s

Type "cd my-blog"
Enter
Sleep 500ms

Type "lpad new-post"
Enter
Sleep 2s

Type "Hello Lambdapad"
Sleep 500ms
Enter
Sleep 800ms

Enter
Sleep 800ms

Enter
Sleep 800ms

Enter
Sleep 800ms

Enter
Sleep 2s

Type "lpad"
Enter
Sleep 2500ms

Type "lpad http &"
Enter
Sleep 2500ms

Type "curl -sI http://localhost:8080/ | head -n 4"
Enter
Sleep 2500ms

Hide
Type "kill %1 2>/dev/null || true"
Enter
Sleep 500ms

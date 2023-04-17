Wscript.Echo Opened_Folders
Function Opened_Folders
   Dim objShellApp,wFolder,Open_Folder,F
   Set objShellApp = CreateObject("Shell.Application")
   For Each wFolder In objShellApp.Windows
       Open_Folder = wFolder.document.Folder.Self.Path
       F = F & Open_Folder & vbcrlf
   Next
   Opened_Folders = F
End Function

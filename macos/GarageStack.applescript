property projectPath : "/Users/billburrows/Documents/Playground/GarageStack"
property dashboardUrl : "http://localhost:5173"

on run
	try
		display notification "Starting services..." with title "GarageStack"
		do shell script "export PATH=\"$HOME/.dotnet:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin\"; cd " & quoted form of projectPath & " && ./start-local.sh"
		do shell script "/usr/bin/open " & quoted form of dashboardUrl
		display notification "Dashboard is ready." with title "GarageStack"
	on error errorMessage
		display dialog "GarageStack could not start:" & return & return & errorMessage buttons {"OK"} default button "OK" with icon stop
	end try
end run

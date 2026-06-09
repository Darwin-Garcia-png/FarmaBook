# Mata Chrome y lo relanza sin CORS para desarrollo Flutter Web
taskkill /F /IM chrome.exe 2>$null
Start-Process "C:\Program Files\Google\Chrome\Application\chrome.exe" "--disable-web-security --user-data-dir=C:\tmp\chrome_dev"
Start-Process "flutter" "run -d chrome --web-renderer html"

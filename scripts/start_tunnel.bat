@echo off
setlocal
pushd "%~dp0.."
echo Starting Cloudflare Tunnel: squashapi.cs-deployment.stream
echo.
"C:\Program Files (x86)\cloudflared\cloudflared.exe" tunnel run squash-api
popd
endlocal

@echo off
setlocal
pushd "%~dp0.."
"C:\Program Files (x86)\cloudflared\cloudflared.exe" tunnel --url http://localhost:5002 --logfile ".cloudflared_tunnel.log" --loglevel info
popd
endlocal

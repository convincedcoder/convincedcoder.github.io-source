robocopy _site ..\convincedcoder.github.io /E /PURGE /XD ".git" /XF ".nojekyll"
cd ..\convincedcoder.github.io

findstr /c:"0.0.0.0" index.html
if %errorlevel% == 0 echo Please make sure to set JEKYLL_ENV=production && pause && exit /b

git add --all
git commit -m "publish new version"
git push

pause
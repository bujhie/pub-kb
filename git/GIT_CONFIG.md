git config --global core.longpaths true
git config --global http.https://dev.azure.com.proxy http://proxy.company.com:8080
git config --global user.name "FirstName.LastName"
git config --global user.email "firstname.lastname@company.com"
git config --global --add --bool push.autoSetupRemote true


git config --global --unset http.https://dev.azure.com.proxy

# Install PowerShell
wget https://github.com/PowerShell/PowerShell/releases/download/v6.0.0-beta.5/powershell-6.0.0_beta.5-1.suse.42.1.x86_64.rpm
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo zypper info libuuid-devel
sudo rpm -Uvh --nodeps ./powershell-6.0.0_beta.5-1.suse.42.1.x86_64.rpm

# Install .NET Core and AzCopy
sudo zypper install libunwind libicu
curl -sSL -o dotnet.tar.gz https://go.microsoft.com/fwlink/?linkid=848824
sudo mkdir -p /opt/dotnet && sudo tar zxf dotnet.tar.gz -C /opt/dotnet
sudo ln -s /opt/dotnet/dotnet /usr/bin

wget -O azcopy.tar.gz https://aka.ms/downloadazcopyprlinux
tar -xf azcopy.tar.gz
sudo ./install.sh
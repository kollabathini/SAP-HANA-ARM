
Param(
    [Parameter(Mandatory)][string] $Uri
)

Configuration ExampleConfiguration{

    Import-DSCResource -Module nx
    Set-StrictMode -Off

    Node  "reboot"{

	nxFile setparamout
	{
	   Ensure = "Present"
    	   Destinationpath = "/tmp/parameter.txt"
    	   Contents="hello world $Uri" 
	   Mode = "755"
	} 


	nxFile ExampleFile {

        DestinationPath = "/tmp/example"
        Contents = $Uri
        Ensure = "Present"
        Type = "File"
    }

	nxFileLine EnableSwap
	{
	   FilePath = "/etc/waagent.conf"
       	   ContainsLine = 'ResourceDisk.EnableSwap = y'
	   DoesNotContainPattern = "ResourceDisk.EnableSwap=n"
	} 

	nxFileLine EnableSwapSize
	{
	   FilePath = "/etc/waagent.conf"
	   ContainsLine = 'ResourceDisk.SwapSizeMB = 163840'
	} 

	nxPackage glibc
	{
 	   Name = "glibc-2.22-51.6"
    	   Ensure = "Present"
    	   PackageManager = "zypper"
	}

	nxPackage systemd
	{
	   Name = "systemd-228-142.1"
    	   Ensure = "Present"
    	   PackageManager = "zypper"
	}

	nxPackage unrar
	{
	   Name = "unrar"
    	   Ensure = "Present"
    	   PackageManager = "zypper"
	}

	nxPackage sapconf
	{
	   Name = "sapconf"
    	   Ensure = "Present"
    	   PackageManager = "zypper"
	}

	nxPackage saptune
	{
	   Name = "saptune"
    	   Ensure = "Present"
    	   PackageManager = "zypper"
	}

	nxFile loginconfdir
	{
   	   Ensure = "Present"
   	   DestinationPath = "/etc/systemd/login.conf.d"
   	   Type = "Directory"
	}

	nxFile setLoginconfd
	{
	   Ensure = "Present"
    	   Destinationpath = "/etc/systemd/login.conf.d/sap.conf"
    	   Contents=@"
[login]`n
UserTasksMax=infinity`n
"@ 
	   Mode = "755"
	   DependsOn = "[nxFile]loginconfdir"
} 

nxScript SetTunedAdm{

    GetScript = @"
#!/bin/bash
exit 1
"@

    SetScript = @"
#!/bin/bash
tuned-adm profile sap-hana
systemctl start tuned
systemctl enable tuned
saptune solution apply HANA
saptune daemon start
"@

    TestScript = @'
#!/bin/bash
exit 1
'@
} 

	nxFileLine BootConf
	{
	   FilePath = "/etc/default/grub"
	   ContainsLine = 'GRUB_CMDLINE_LINUX_DEFAULT="transparent_hugepage=never numa_balancing=disable intel_idle.max_cstate=1 processor.max_cstate=1"'
	} 

nxScript grubmkconfig{

    GetScript = @"
#!/bin/bash
exit 1
"@

    SetScript = @"
#!/bin/bash
grub2-mkconfig -o /boot/grub2/grub.cfg
echo 1 > /root/boot-requested
"@

    TestScript = @'
#!/bin/bash
filecount=`cat /root/boot-done`
if [ $filecount -gt 0 ]
then
    exit 0
else
    exit 1
fi
'@

	   DependsOn = "[nxFileLine]BootConf"
} 



nxScript logicalvols{

    GetScript = @"
#!/bin/bash
exit 1
"@

    SetScript = @"
#!/bin/bash
pvcreate /dev/sd[cdefg]
vgcreate hanavg /dev/sd[fg]
lvcreate -l 80%FREE -n datalv hanavg
lvcreate -l 20%FREE -n loglv hanavg
mkfs.xfs /dev/hanavg/datalv
mkfs.xfs /dev/hanavg/loglv
"@

    TestScript = @'
#!/bin/bash
filecount=`vgdisplay | grep hanavg | wc -l`
if [ $filecount -gt 0 ]
then
    exit 0
else
    exit 1
fi

'@
} 

	nxFile hanadatadird
	{
   	   Ensure = "Present"
   	   DestinationPath = "/hanadata"
   	   Type = "Directory"
	}

	nxFile hanalogdird
	{
   	   Ensure = "Present"
   	   DestinationPath = "/hanalog"
   	   Type = "Directory"
	}

nxScript logicalvols2{

    GetScript = @"
#!/bin/bash
exit 1
"@

    SetScript = @"
#!/bin/bash
vgcreate sharedvg /dev/sdc 
vgcreate backupvg /dev/sdd  
vgcreate usrsapvg /dev/sde 
lvcreate -l 100%FREE -n sharedlv sharedvg 
lvcreate -l 100%FREE -n backuplv backupvg 
lvcreate -l 100%FREE -n usrsaplv usrsapvg 
mkfs -t xfs /dev/sharedvg/sharedlv 
mkfs -t xfs /dev/backupvg/backuplv 
mkfs -t xfs /dev/usrsapvg/usrsaplv
"@

    TestScript = @'
#!/bin/bash
filecount=`vgdisplay | grep sharedvg | wc -l`
if [ $filecount -gt 0 ]
then
    exit 0
else
    exit 1
fi

'@
} 


	nxFile hanadatadir
	{
   	   Ensure = "Present"
   	   DestinationPath = "/hana/data"
   	   Type = "Directory"
	}

	nxFile hanalogdir
	{
   	   Ensure = "Present"
   	   DestinationPath = "/hana/log"
   	   Type = "Directory"
	}

	nxFile hanasharedir
	{
   	   Ensure = "Present"
   	   DestinationPath = "/hana/shared"
   	   Type = "Directory"
	}


	nxFile usrsapdir
	{
   	   Ensure = "Present"
   	   DestinationPath = "/usr/sap"
   	   Type = "Directory"
	}

	nxFile hanabackupdir
	{
   	   Ensure = "Present"
   	   DestinationPath = "/hana/backup"
   	   Type = "Directory"
	}


	nxFileLine fstabshared
	{
	   FilePath = "/etc/fstab"
       	   ContainsLine = '/dev/sharedvg/sharedlv /hana/shared xfs defaults 1 0 '
	} 

	nxFileLine fstabbackup
	{
	   FilePath = "/etc/fstab"
       	   ContainsLine = '/dev/backupvg/backuplv /hana/backup xfs defaults 1 0 '
	} 

	nxFileLine fstabusrsap
	{
	   FilePath = "/etc/fstab"
       	   ContainsLine = '/dev/usrsapvg/usrsaplv /usr/sap xfs defaults 1 0 '
	} 

	nxFileLine fstabdatalv
	{
	   FilePath = "/etc/fstab"
       	   ContainsLine = '/dev/hanavg/datalv /hana/data xfs nofail 0 0  '
	} 

	nxFileLine fstabloglv
	{
	   FilePath = "/etc/fstab"
       	   ContainsLine = '/dev/hanavg/loglv /hana/log xfs nofail 0 0  '
	} 

nxScript mounthanashared{

    GetScript = @"
#!/bin/bash
exit 1
"@

    SetScript = @"
#!/bin/bash
mount -t xfs /dev/sharedvg/sharedlv /hana/shared
mount -t xfs /dev/backupvg/backuplv /hana/backup 
mount -t xfs /dev/usrsapvg/usrsaplv /usr/sap
mount -t xfs /dev/hanavg/datalv /hana/data
mount -t xfs /dev/hanavg/loglv /hana/log 
"@

    TestScript = @'
#!/bin/bash
filecount=`mount | grep /hana/shared | wc -l`
if [ $filecount -gt 0 ]
then
    exit 0
else
    exit 1
fi
'@

} 

	nxFile sapbits
	{
   	   Ensure = "Present"
   	   DestinationPath = "/hana/shared/sapbits"
   	   Type = "Directory"
	}

	nxFile hanapart1
	{
	   Ensure = "Present"
	   SourcePath = "$Uri/51052325_part1.exe"
    	   Destinationpath = "/hana/shared/sapbits/51052325_part1.exe"
	   Mode = "755"
	} 

	nxFile hanapart2
	{
	   Ensure = "Present"
	   SourcePath = "$Uri/51052325_part2.rar"
    	   Destinationpath = "/hana/shared/sapbits/51052325_part2.rar"
	   Mode = "755"
	} 

	nxFile hanapart3
	{
	   Ensure = "Present"
	   SourcePath = "$Uri/51052325_part3.rar"
    	   Destinationpath = "/hana/shared/sapbits/51052325_part3.rar"
	   Mode = "755"
	} 

	nxFile hanapart4
	{
	   Ensure = "Present"
	   SourcePath = "$Uri/51052325_part4.rar"
    	   Destinationpath = "/hana/shared/sapbits/51052325_part4.rar"
	   Mode = "755"
	} 

	nxFile hanapart5
	{
	   Ensure = "Present"
	   SourcePath = "$Uri/hdbinst.cfg"
    	   Destinationpath = "/hana/shared/sapbits/hdbinst.cfg"
	   Mode = "755"
	} 

nxScript unpackrar{

    GetScript = @"
#!/bin/bash
exit 1
"@

    SetScript = @"
#!/bin/bash
unrar x 51052325_part1.exe
"@

    TestScript = @'
#!/bin/bash
filecount=`ls -l /hana/shared/sapbits/51052325 | wc -l`
if [ $filecount -gt 0 ]
then
    exit 0
else
    exit 1
fi

'@
} 


nxScript hdbinstconfig{

    GetScript = @"
#!/bin/bash
exit 1
"@

    SetScript = @"
#!/bin/bash
cd /hana/shared/sapbits
myhost=`hostname`
sedcmd="s/REPLACE-WITH-HOSTNAME/$myhost/g"
cat hdbinst.cfg | sed $sedcmd > hdbinst-local.cfg
"@

    TestScript = @'
#!/bin/bash
filecount=`grep HOSTNAME-REPLACEME /hana/shared/sapbits/hdbinst-local.cfg | wc -l`
if [ $filecount -gt 0 ]
then
    exit 0
else
    exit 1
fi

'@
} 

nxScript bootrequest{

    GetScript = @"
#!/bin/bash
exit 1
"@

    SetScript = @"
#!/bin/bash
mv /root/boot-requested /root/boot-done
reboot
"@

    TestScript = @'
#!/bin/bash
filecount=`ls /root | grep boot-requested | wc -l`
if [ $filecount -gt 0 ]
then
    exit 1
else
    exit 0
fi
'@

	   DependsOn = "[nxFileLine]BootConf"
} 


    }
}
ExampleConfiguration -OutputPath:".\"
# zbx-intel-rste-tpl
Zabbix template for monitoring integrated Intel RSTe RAID

1. Copy "rst" folder to yours zabbix_agent/scripts folder.
2. Change path to your RST_cli folder in variable $clipath in powershell script
3. Start script with "rst.getcli" parameter. Script will check your driver version and make decision on what CLI version to use and write it to RST.txt (this made for faster execution of script, because it will take 5-10 secs to get driver version from WMI, it's much more faster to take CLI version from txt file.) Zabbix will make this query too every 3 hours just to update in case of driver update.
4. Add this string to your UserParameters in zabbix_agent config (change path to script to yours):
   `UserParameter=rst.raid[*],powershell.exe -NoProfile -NoLogo -File "path to zbx-intel_rst.ps1 script" $1 $2 $3 $4`
5. Import zabbix template and connect it to host with RSTe RAID.

# This script will set up the system to force Amazon to run Sysprep upon image creation.
# It will also request the password be reset during specialization to a random value,
# which will be exposed via the EC2 console.
$EC2SettingsFile="C:\\Program Files\\Amazon\\Ec2ConfigService\\Settings\\BundleConfig.xml"
$xml = [xml](get-content $EC2SettingsFile)
$xmlElement = $xml.get_DocumentElement()

foreach ($element in $xmlElement.Property)
{
    if ($element.Name -eq "AutoSysprep")
    {
        $element.Value="Yes"
    }
	if ($element.Name -eq "SetPasswordAfterSysprep")
    {
        $element.Value="Yes"
    }
}
$xml.Save($EC2SettingsFile)

Write-Output "Set EC2 Bundle Configuration"
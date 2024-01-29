![This is an image](https://www.inthecloud247.com/wp-content/uploads/2022/06/GitHub-PowerShell.png)

This is an example of a solution to automatically configure the time zone on a Windows device (for example during Autopilot enrollment).
*The original solution used is not my own creation, but was previously found in a comment on another website.*
*As I couldn't find that comment anymore and I think it might still be interesting for others I share it here.*

*The solution makes use of https://ipinfo.io to retrieve the location of the device. Please note the API request limits of this service!*
*The solution also makes use of Bing Maps Dev Center. Via the API of this service the loction is converted to a Time Zone.*
*Check the license agreement if a basic key (free) key is suitable for your needs!*
An option to deploy the scripts is to wrap them as a win32 app and deploy the package with Microsoft Intune.

The logs are saved on %programdata%\Microsoft\IntuneManagementExtension\Logs. This makes it available in the Device Diagnostics for Intune.

I'll share a blog post later on this solution to describe this solution in more detail.
My website can be found here [Here](https://www.inthecloud247.com/)

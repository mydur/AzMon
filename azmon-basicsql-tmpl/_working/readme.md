# azmon-basicwvd-tmpl

The purpose of this template is to make the workspace ready for Azure Windows Virtual Desktop (WVD) monitoring. This is done by adding datasources (performance) and some saved searches.

> **Note:** You will also find some lines in the template to deploy the AML workspace itself. This is needed because the sub-resources deployed later (saved queries, datasources) require this. Because the workspace already exists no actual deployment will take place.

The template adds datasources and saved queries to the AML workspace. 

&nbsp;

_Datasources (perf):_
| #   | Name                             | Category                   | Counter                                                | Instance | Interval |
| --- | :------------------------------- | :------------------------- | :----------------------------------------------------- | :------- | :------- |
| 1   | TermSvcPctProcessorTime          | Terminal Services Sessiond | % Processor Time                                       | \*       | 60       |
| 2   | TermSvcActiveSessions            | Terminal Services Session  | Active Sessions                                        | \*       | 60       |
| 3   | TermSvcInActiveSessions          | Terminal Services Session  | Inactive Sessions                                      | \*       | 60       |
| 4   | TermSvcTotalSessions             | Terminal Services Session  | Total Sessions                                         | \*       | 60       |
| 5   | ProcessPctUserTime               | Process                    | % User Time                                            | \*       | 60       |
| 6   | ProcessIOReadOpsSec              | Process                    | IO Read Operations/sec                                 | \*       | 60       |
| 7   | ProcessIOWriteOpsSec             | Process                    | IO Write Operations/sec                                | \*       | 60       |
| 8   | ProcessThreadCount               | Process                    | Thread Count                                           | \*       | 60       |
| 9   | ProcessWorkingSet                | Process                    | Working Set                                            | \*       | 60       |
| 10  | RemFXGraphAvgEncTime             | RemoteFX Graphics          | Average Encoding Time                                  | \*       | 60       |
| 11  | RemFXGraphAvgFramSkipInsufClient | RemoteFX Graphics          | Frames Skipped/Second - Insufficient Client Resources  | \*       | 60       |
| 12  | RemFXGraphAvgFramSkipInsufNetw   | RemoteFX Graphics          | Frames Skipped/Second - Insufficient Network Resources | \*       | 60       |
| 13  | RemFXGraphAvgFramSkipInsufServer | RemoteFX Graphics          | Frames Skipped/Second - Insufficient Server Resources  | \*       | 60       |
| 14  | RemFXNetwCurTCPBandw             | RemoteFX Network           | Current TCP Bandwidth                                  | \*       | 60       |
| 15  | RemFXNetwCurTCPRTT               | RemoteFX Network           | Current TCP RTT                                        | \*       | 60       |
| 16  | RemFXNetwCurUDPBandw             | RemoteFX Network           | Current UDP Bandwidth                                  | \*       | 60       |
| 17  | RemFXNetwCurUDPRTT               | RemoteFX Network           | Current TCP RTT                                        | \*       | 60       |
| 18  | RemFXNetwCurUDPBandw             | RemoteFX Network           | Current UDP Bandwidth                                  | \*       | 60       |
| 19  | RemFXNetwCurUDPRTT               | RemoteFX Network           | Current UDP RTT                                        | \*       | 60       |
| 20  | PhysDiskAvgDiskByteRead          | PhysicalDisk               | Avg. Disk Bytes/Read                                   | \*       | 60       |
| 21  | PhysDiskAvgDiskByteWrite         | PhysicalDisk               | Avg. Disk Bytes/Write                                  | \*       | 60       |
| 22  | PhysDiskAvgDiskSecRead           | PhysicalDisk               | Avg. Disk sec/Read                                     | \*       | 60       |
| 23  | PhysDiskAvgDiskSecWrite          | PhysicalDisk               | Avg. Disk sec/Write                                    | \*       | 60       |
| 24  | PhysDiskAvgDiskByteTrans         | PhysicalDisk               | Avg. Disk Bytes/Transfer                               | \*       | 60       |
| 25  | PhysDiskAvgDiskSecTrans          | PhysicalDisk               | Avg. Disk sec/Transfer                                 | \*       | 60       |

&nbsp;

_Saved searches:_
| #   | Name                             | Category                 | Display name                                           |
| --- | :------------------------------- | :----------------------- | :----------------------------------------------------- |
| 1   | searchWVDCurActiveSessions       | Getronics WVD Monitoring | WVD - Current Active Sessions                          |
| 2   | searchWVDCurDisconnectedSessions | Getronics WVD Monitoring | WVD - Current disconnected sessions                    |
| 3   | searchWVDCurTotalSessions        | Getronics WVD Monitoring | WVD - Current total sessions                           |
| 4   | searchWVDAvgSessions             | Getronics WVD Monitoring | WVD - Average sessions                                 |
| 5   | searchWVDMaxSessions             | Getronics WVD Monitoring | WVD - Max sessions                                     |
| 6   | searchWVDSessionDurPerUser       | Getronics WVD Monitoring | WVD - Session duration per user                        |
| 7   | searchWVDLogicalDisk             | Getronics WVD Monitoring | WVD - Logical Disk                                     |
| 8   | searchWVDProcessor               | Getronics WVD Monitoring | WVD - Processor                                        |
| 9   | searchWVDNetwork                 | Getronics WVD Monitoring | WVD - Network                                          |
| 10  | searchWVDMemory                  | Getronics WVD Monitoring | WVD - Memory                                           |
| 11  | searchWVDProcUtilPerUser         | Getronics WVD Monitoring | WVD - Processor utilization per user                   |
| 12  | searchWVDInOutNetBytesPerUser    | Getronics WVD Monitoring | WVD - Inbound/outbound network bytes per user          |
| 13  | searchWVDRTTPerfForRDP           | Getronics WVD Monitoring | WVD - RTT perf counter for RDP                         |
| 14  | searchWVDClientTypeDistrib       | Getronics WVD Monitoring | WVD - Windows Virtual Desktop client type distribution |
| 15  | searchWVDClientTypes             | Getronics WVD Monitoring | WVD - Client types                                     |
| 16  | searchWVDAgentHealth             | Getronics WVD Monitoring | WVD - Windows Virtual Desktop agent health status      |
| 17  | searchWVDDailyActiveUsers        | Getronics WVD Monitoring | WVD - Daily active users                               |
| 18  | searchWVDTop10HostsCPU           | Getronics WVD Monitoring | WVD - Top 10 hosts by CPU utilization                  |
| 19  | searchWVDDiskPerf                | Getronics WVD Monitoring | WVD - Disk performance                                 |

&nbsp;

To be able to re-use the template the following parameters were introduced:

- **Project:** An inidicator string for the customer or project that this will be used for. What you enter here will be used in tags but also in the names for the different resources that are created.
- **Environment:** Can be one of the following: dev-test-acc-prod.
- **AMLWorkspaceName:** The actual name of the log analytics workspace that can be found in the resource group of which the name is stored in AMLResourceGroup.
- **AMLWorkspaceRGName:** The resource group in which the log analytics workspace was installed by the azmon-basic-tmpl template.
- **Location:** The region in which the deployment will take place.
- **DataRetention:** Number of retention days in the PerGB2018 pricing tier (31-730).
- **CreatedOn:** This paramters is in fact a variable that holds the current date and time to be added as a tag to the resources created by this template. Because of technical reasons this has to be a parameter and not a variable. The default value for the parameter is the outcome of the function [utcNow()]
- **EndsOn:** This parameter provides an indication of when the created resource should be end-of-life. It helps when cleaning up your Azure resources to have an idea when a resource isn't used anymore. The format of the date provided is yyyymmdd. When there's no end date available you should use 99999999.
- **CreatedBy:** A free text field to provide information about the person or team that created the resource. Isn't to be confused with the OwnedBy field.
- **OwnedBy:** A free text field to provide information about the person or team that owns the resource. Isn't to be confused with the CreatedBy field.

&nbsp;

Tags are very important in Azure Governance as they help you in filtering the resources you're using. Resources created by this template get the following tags of which the values are stored in a variable with the same name:

- **TemplateId:** String identifier for the current template. (azmon-basic)
- **TemplateVersion:** Version of the template.
- **CreatedOn:** Current timestamp.
- **Project:** Project or customer identifier.
- **EndsOn:** This parameter provides an indication of when the created resource should be end-of-life. It helps when cleaning up your Azure resources to have an idea when a resource isn't used anymore. The format of the date provided is yyyymmdd. When there's no end date available you should use 99999999.
- **CreatedBy:** A free text field to provide information about the person or team that created the resource. Isn't to be confused with the OwnedBy field.
- **OwnedBy:** A free text field to provide information about the person or team that owns the resource. Isn't to be confused with the CreatedBy field.

&nbsp;

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fmydur%2FAzMon%2Fmaster%2Fazmon-basicwvd-tmpl%2F%5Fworking%2Ftemplate.json" target="_blank">
<img src="http://azuredeploy.net/deploybutton.png"/>
</a><br />

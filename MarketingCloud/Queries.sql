-- Annual Appointment Reminders
SELECT
c.Id AS SubscriberKey,
c.Email AS Email,
c.FirstName AS FirstName,
c.Last_Physical_Exam_Date__c AS LastPhysicalExamDate

FROM Contact_Salesforce AS c

LEFT JOIN
(SELECT v.Donor__c
FROM Visit__c_Salesforce AS v
WHERE v.Appointment_Datetime__c > GETDATE()
AND v.Physical_Exam__c = 0)
AS vis
ON vis.Donor__c = c.Id

LEFT JOIN
(SELECT a.SubscriberKey
FROM "Annual Physical Reminder" AS a
WHERE DATEDIFF(DAY, GETDATE(), a.DateAdded) < 28)
AS apr
ON apr.SubscriberKey = c.Id

WHERE DATEDIFF(DAY, GETDATE(), DATEADD(YEAR, 1, c.Last_Physical_Exam_Date__c)) = 28 AND
vis.Donor__c IS NULL AND
apr.SubscriberKey IS NULL

-- Apology Campaign
SELECT v.Donor__c AS SubscriberKey,
c.Email AS Email,
c.Firstname AS FirstName,
v.Id AS VisitId,
cdt.Center__c AS CenterId,
cent.Apology_Campaign_Payment_Amount__c AS CompensationAmount

FROM Visit__c_Salesforce AS v

INNER JOIN Contact_Salesforce AS c
ON c.Id = v.Donor__c

INNER JOIN Account_Salesforce AS cent
ON cent.Id = v.Center__c

INNER JOIN Center_Donation_Type__c_Salesforce AS cdt
ON cdt.Center__c = cent.Id

LEFT JOIN
(SELECT a.VisitId
FROM "Apology Campaign" AS a)
AS ac
ON ac.VisitId = v.Id

WHERE ac.VisitId IS NULL
AND v.Cycle_Time__c > cent.Apology_Campaign_Time_Threshold__c
AND cent.Apology_Campaign_Active__c = 1

-- Donor Visit Metrics (Large query failing in SFMC - retaining in case support fixes Case #44344859
SELECT c.Id AS SubscriberKey,
s.VisitCount AS CountScheduled,
s.NextScheduleDate AS NextScheduleDate,
s.LatestScheduledDate AS LatestScheduledDate,
d.TotalDonations AS CountTotalDonations,
d.FirstDonationDate AS FirstDonationDate,
d.LastDonationDate AS LastDonationDate,
d2.TotalDonations AS CountDonationsLast365Days

FROM Contact_Salesforce AS c

INNER JOIN
(SELECT v.Donor__c AS DonorId
FROM Visit__c_Salesforce AS v
)
AS allv
ON c.Id = allv.DonorId

-- Lifetime Metrics
LEFT JOIN
(SELECT v2.Donor__c AS DonorId,
COUNT(Id) AS VisitCount,
MIN(Appointment_Datetime__c) AS NextScheduleDate,
MAX(Appointment_Datetime__c) AS LatestScheduledDate
FROM Visit__c_Salesforce AS v2
WHERE v2.Status__c = 'Scheduled'
GROUP BY v2.Donor__c
)
AS s
ON c.Id = s.DonorId

LEFT JOIN
(SELECT v3.Donor__c AS DonorId,
Count(Id) AS TotalDonations,
MIN(Appointment_Datetime__c) AS FirstDonationDate,
MAX(Appointment_Datetime__c) AS LastDonationDate
FROM Visit__c_Salesforce AS v3
WHERE v3.Outcome__c = 'Donation'
GROUP BY v3.Donor__c
)
AS d
ON c.Id = d.DonorId

-- Last 365 Days
LEFT JOIN
(SELECT v4.Donor__c AS DonorId,
Count(Id) AS TotalDonations
FROM Visit__c_Salesforce AS v4
WHERE v4.Outcome__c = 'Donation' AND
v4.Appointment_Datetime__c >= DATEADD(DAY, -365, GETUTCDATE())
GROUP BY v4.Donor__c
)
AS d2
ON c.Id = d2.DonorId

-- Standalone Donations Last 365 Days
SELECT v4.Donor__c AS SubscriberKey,
Count(Id) AS CountDonationsLast365Days
FROM Visit__c_Salesforce AS v4
WHERE v4.Outcome__c = 'Donation' AND
v4.Appointment_Datetime__c >= DATEADD(DAY, -365, GETUTCDATE())
GROUP BY v4.Donor__c

-- Standalone Lifetime Donations
SELECT v3.Donor__c AS SubscriberKey,
Count(Id) AS CountTotalDonations,
MIN(Appointment_Datetime__c) AS FirstDonationDate,
MAX(Appointment_Datetime__c) AS LastDonationDate
FROM Visit__c_Salesforce AS v3
WHERE v3.Outcome__c = 'Donation'
GROUP BY v3.Donor__c

-- Standalone Scheduled Visits
SELECT v2.Donor__c AS SubscriberKey,
COUNT(Id) AS CountScheduled,
MIN(Appointment_Datetime__c) AS NextScheduledDate,
MAX(Appointment_Datetime__c) AS LatestScheduledDate
FROM Visit__c_Salesforce AS v2
WHERE v2.Status__c = 'Scheduled'
GROUP BY v2.Donor__c
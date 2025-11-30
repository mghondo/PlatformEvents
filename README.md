# Big Deal Alert - Platform Events Solution

A Salesforce Platform Events implementation that demonstrates event-driven architecture for real-time opportunity tracking and alerting when high-value deals close.

## 🎯 Overview

This solution automatically publishes platform events when opportunities close with amounts exceeding $100,000, triggering automated follow-up tasks and maintaining an audit log of all big deals. It showcases enterprise-level event-driven patterns in Salesforce.

## 🏗️ Architecture

### Components

#### Platform Event
- **Big_Deal_Alert__e** - High-volume platform event for broadcasting big deal notifications
  - `Opportunity_Id__c` - Reference to the source opportunity
  - `Opportunity_Name__c` - Name of the closed opportunity
  - `Amount__c` - Deal amount
  - `Account_Name__c` - Associated account name
  - `Owner_Name__c` - Opportunity owner's name
  - `Close_Date__c` - Date the deal closed

#### Custom Object
- **Big_Deal_Log__c** - Persistent storage for all big deal alerts
  - `Opportunity__c` - Lookup relationship to Opportunity
  - `Amount__c` - Currency field for deal value
  - `Alerted_Date__c` - Timestamp of when alert was created
  - `Account_Name__c` - Account name for reporting

#### Apex Classes
- **BigDealPublisher** - Publishes platform events for qualifying opportunities
  - `publishBigDeal(Opportunity opp)` - Publishes single opportunity event
  - `publishBigDeals(List<Opportunity> opps)` - Bulk publishing for multiple opportunities
  - `MINIMUM_AMOUNT` constant set to $100,000

- **BigDealSubscriberHandler** - Processes incoming big deal events
  - Creates follow-up tasks for opportunity owners
  - Generates Big_Deal_Log__c records for audit trail
  - Handles bulk operations efficiently

#### Triggers
- **OpportunityBigDealTrigger** - After update trigger on Opportunity
  - Fires when opportunities transition to "Closed Won"
  - Filters for amounts >= $100,000
  - Queries related data and publishes events

- **BigDealAlertTrigger** - After insert trigger on Big_Deal_Alert__e
  - Subscribes to platform events
  - Routes to BigDealSubscriberHandler for processing

#### Test Class
- **BigDealPlatformEventTest** - Comprehensive test coverage (88%)
  - Tests event publishing for single and multiple opportunities
  - Validates subscriber task and log creation
  - Tests trigger integration
  - Includes negative test cases and edge scenarios

## 📋 Prerequisites

- Salesforce DX CLI
- Authenticated DevHub org
- Scratch org or sandbox for deployment

## 🚀 Installation

1. Clone the repository:
```bash
git clone https://github.com/mghondo/PlatformEvents.git
cd PlatformEvents
```

2. Create a scratch org (optional):
```bash
sf org create scratch --definition-file config/project-scratch-def.json --alias bigdeal-org --duration-days 7
```

3. Deploy the source:
```bash
sf project deploy start --target-org YOUR_ORG_ALIAS
```

4. Run tests to verify installation:
```bash
sf apex run test --target-org YOUR_ORG_ALIAS --code-coverage --result-format human
```

## 💼 Business Use Cases

### Automatic Deal Tracking
When sales representatives close high-value opportunities, the system automatically:
1. Publishes a platform event with deal details
2. Creates a follow-up task for customer success engagement
3. Logs the deal in a custom object for executive reporting

### Real-time Notifications
Platform events enable real-time integrations:
- External systems can subscribe to events via CometD
- Process Builder and Flows can react to big deals
- Email alerts or Slack notifications can be triggered

### Audit and Compliance
The Big_Deal_Log__c object provides:
- Historical tracking of all major deals
- Timestamp data for SLA monitoring
- Account-level deal aggregation for analytics

## 🧪 Testing

The solution includes comprehensive test coverage:

```apex
// Run all tests
BigDealPlatformEventTest.runTests();
```

Test scenarios covered:
- Single opportunity publishing
- Bulk opportunity publishing
- Subscriber task creation
- Log record generation
- Trigger integration
- Null handling
- Threshold validation

## 🔧 Configuration

### Adjusting the Threshold
To modify the minimum amount threshold, update the constant in `BigDealPublisher.cls`:

```apex
public static final Decimal MINIMUM_AMOUNT = 100000; // Change this value
```

### Customizing Follow-up Tasks
Edit the task creation logic in `BigDealSubscriberHandler.cls`:

```apex
followUpTask.ActivityDate = Date.today().addDays(3); // Adjust follow-up timing
followUpTask.Priority = 'High'; // Modify priority
```

## 📊 Monitoring

Monitor platform event usage:
1. Navigate to Setup → Platform Events
2. View Big_Deal_Alert__e usage metrics
3. Check event delivery status

Query event logs:
```sql
SELECT Id, Opportunity__c, Amount__c, Alerted_Date__c 
FROM Big_Deal_Log__c 
WHERE Alerted_Date__c = TODAY
ORDER BY Amount__c DESC
```

## 🔍 Key Features

- **Event-Driven Architecture** - Decoupled publisher/subscriber pattern
- **Bulk Processing** - Handles multiple opportunities efficiently
- **Error Handling** - Graceful failure management with debug logging
- **High Volume Support** - Configured for high-volume event processing
- **Related Data Queries** - Enriches events with Account and Owner information
- **Task Automation** - Automatic follow-up task generation

## 🛠️ Development Patterns

This solution demonstrates several Salesforce best practices:

1. **Bulkification** - All operations handle collections efficiently
2. **Separation of Concerns** - Publisher, subscriber, and handler logic separated
3. **Defensive Programming** - Null checks and error handling throughout
4. **Test-Driven Development** - 88% code coverage with meaningful assertions
5. **Platform Event Patterns** - Proper use of high-volume events with PublishAfterCommit

## 📈 Performance Considerations

- Platform events are processed asynchronously
- High-volume configuration supports up to 250,000 events per hour
- PublishAfterCommit behavior ensures transaction integrity
- Bulk DML operations minimize governor limit consumption

## 🤝 Contributing

Feel free to submit issues and enhancement requests!

## 📄 License

This project is available for portfolio demonstration and educational purposes.

## 👤 Author

**Morgan Hondros**  
Salesforce Developer  
[GitHub Profile](https://github.com/mghondo)

---

*Built to demonstrate Platform Events, event-driven architecture, and enterprise integration patterns in Salesforce.*
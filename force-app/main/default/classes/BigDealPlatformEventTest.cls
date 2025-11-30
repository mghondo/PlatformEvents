@isTest
public class BigDealPlatformEventTest {
    
    @testSetup
    static void setup() {
        Account testAccount = new Account(
            Name = 'Test Account'
        );
        insert testAccount;
        
        List<Opportunity> opportunities = new List<Opportunity>();
        
        Opportunity bigDealOpp = new Opportunity(
            Name = 'Big Deal Opportunity',
            AccountId = testAccount.Id,
            Amount = 150000,
            CloseDate = Date.today(),
            StageName = 'Prospecting'
        );
        opportunities.add(bigDealOpp);
        
        Opportunity smallDealOpp = new Opportunity(
            Name = 'Small Deal Opportunity',
            AccountId = testAccount.Id,
            Amount = 50000,
            CloseDate = Date.today(),
            StageName = 'Prospecting'
        );
        opportunities.add(smallDealOpp);
        
        insert opportunities;
    }
    
    @isTest
    static void testPublishBigDeal_SingleOpportunity() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        User currentUser = [SELECT Id, Name FROM User WHERE Id = :UserInfo.getUserId()];
        
        Opportunity opp = new Opportunity(
            Name = 'Test Big Deal',
            Amount = 200000,
            CloseDate = Date.today(),
            StageName = 'Closed Won',
            AccountId = acc.Id,
            OwnerId = currentUser.Id
        );
        opp.Account = new Account(Id = acc.Id, Name = 'Test Account');
        opp.Owner = currentUser;
        
        Test.startTest();
        BigDealPublisher.publishBigDeal(opp);
        Test.stopTest();
        
        List<Big_Deal_Log__c> logs = [SELECT Id, Amount__c, Account_Name__c FROM Big_Deal_Log__c];
        System.assertEquals(1, logs.size(), 'Should create one log record');
        System.assertEquals(200000, logs[0].Amount__c, 'Amount should match');
        System.assertEquals('Test Account', logs[0].Account_Name__c, 'Account name should match');
    }
    
    @isTest
    static void testPublishBigDeals_MultipleOpportunities() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        User currentUser = [SELECT Id, Name FROM User WHERE Id = :UserInfo.getUserId()];
        
        List<Opportunity> opps = new List<Opportunity>();
        
        Opportunity bigOpp1 = new Opportunity(
            Name = 'Big Deal 1',
            Amount = 150000,
            CloseDate = Date.today(),
            StageName = 'Closed Won',
            AccountId = acc.Id,
            OwnerId = currentUser.Id
        );
        bigOpp1.Account = new Account(Id = acc.Id, Name = 'Test Account');
        bigOpp1.Owner = currentUser;
        opps.add(bigOpp1);
        
        Opportunity bigOpp2 = new Opportunity(
            Name = 'Big Deal 2',
            Amount = 250000,
            CloseDate = Date.today(),
            StageName = 'Closed Won',
            AccountId = acc.Id,
            OwnerId = currentUser.Id
        );
        bigOpp2.Account = new Account(Id = acc.Id, Name = 'Test Account');
        bigOpp2.Owner = currentUser;
        opps.add(bigOpp2);
        
        Opportunity smallOpp = new Opportunity(
            Name = 'Small Deal',
            Amount = 50000,
            CloseDate = Date.today(),
            StageName = 'Closed Won',
            AccountId = acc.Id,
            OwnerId = currentUser.Id
        );
        smallOpp.Account = new Account(Id = acc.Id, Name = 'Test Account');
        smallOpp.Owner = currentUser;
        opps.add(smallOpp);
        
        Test.startTest();
        BigDealPublisher.publishBigDeals(opps);
        Test.stopTest();
        
        List<Big_Deal_Log__c> logs = [SELECT Id, Amount__c FROM Big_Deal_Log__c ORDER BY Amount__c];
        System.assertEquals(2, logs.size(), 'Should create two log records for big deals only');
        System.assertEquals(150000, logs[0].Amount__c, 'First amount should be 150000');
        System.assertEquals(250000, logs[1].Amount__c, 'Second amount should be 250000');
    }
    
    @isTest
    static void testSubscriberHandler_CreatesTaskAndLog() {
        Opportunity opp = [SELECT Id, OwnerId, Name FROM Opportunity WHERE Name = 'Big Deal Opportunity' LIMIT 1];
        
        List<Big_Deal_Alert__e> events = new List<Big_Deal_Alert__e>();
        Big_Deal_Alert__e event = new Big_Deal_Alert__e();
        event.Opportunity_Id__c = opp.Id;
        event.Opportunity_Name__c = opp.Name;
        event.Amount__c = 150000;
        event.Account_Name__c = 'Test Account';
        event.Close_Date__c = Date.today();
        events.add(event);
        
        Test.startTest();
        BigDealSubscriberHandler.handleBigDealEvents(events);
        Test.stopTest();
        
        List<Task> tasks = [SELECT Id, Subject, WhatId, OwnerId FROM Task WHERE WhatId = :opp.Id];
        System.assertEquals(1, tasks.size(), 'Should create one task');
        System.assertEquals('Follow up on Big Deal: ' + opp.Name, tasks[0].Subject, 'Task subject should match');
        System.assertEquals(opp.OwnerId, tasks[0].OwnerId, 'Task should be assigned to opportunity owner');
        
        List<Big_Deal_Log__c> logs = [SELECT Id, Opportunity__c, Amount__c, Account_Name__c FROM Big_Deal_Log__c];
        System.assertEquals(1, logs.size(), 'Should create one log record');
        System.assertEquals(opp.Id, logs[0].Opportunity__c, 'Log should be linked to opportunity');
        System.assertEquals(150000, logs[0].Amount__c, 'Amount should match');
    }
    
    @isTest
    static void testOpportunityTrigger_PublishesEventOnClosedWon() {
        Opportunity opp = [SELECT Id, StageName FROM Opportunity WHERE Name = 'Big Deal Opportunity' LIMIT 1];
        
        Test.startTest();
        opp.StageName = 'Closed Won';
        update opp;
        Test.stopTest();
        
        List<Big_Deal_Log__c> logs = [SELECT Id, Amount__c FROM Big_Deal_Log__c];
        System.assertEquals(1, logs.size(), 'Should create one log record after trigger');
        System.assertEquals(150000, logs[0].Amount__c, 'Amount should match');
        
        List<Task> tasks = [SELECT Id FROM Task WHERE WhatId = :opp.Id];
        System.assertEquals(1, tasks.size(), 'Should create one task after trigger');
    }
    
    @isTest
    static void testOpportunityTrigger_NoEventForSmallDeal() {
        Opportunity opp = [SELECT Id, StageName FROM Opportunity WHERE Name = 'Small Deal Opportunity' LIMIT 1];
        
        Test.startTest();
        opp.StageName = 'Closed Won';
        update opp;
        Test.stopTest();
        
        List<Big_Deal_Log__c> logs = [SELECT Id FROM Big_Deal_Log__c];
        System.assertEquals(0, logs.size(), 'Should not create log for small deal');
        
        List<Task> tasks = [SELECT Id FROM Task WHERE WhatId = :opp.Id];
        System.assertEquals(0, tasks.size(), 'Should not create task for small deal');
    }
    
    @isTest
    static void testPublishBigDeal_NotWon() {
        Opportunity opp = new Opportunity(
            Name = 'Lost Big Deal',
            Amount = 200000,
            CloseDate = Date.today(),
            StageName = 'Closed Lost'
        );
        
        Test.startTest();
        BigDealPublisher.publishBigDeal(opp);
        Test.stopTest();
        
        List<Big_Deal_Log__c> logs = [SELECT Id FROM Big_Deal_Log__c];
        System.assertEquals(0, logs.size(), 'Should not create log for lost deal');
    }
    
    @isTest
    static void testPublishBigDeal_NullOpportunity() {
        Test.startTest();
        BigDealPublisher.publishBigDeal(null);
        Test.stopTest();
        
        List<Big_Deal_Log__c> logs = [SELECT Id FROM Big_Deal_Log__c];
        System.assertEquals(0, logs.size(), 'Should handle null opportunity gracefully');
    }
    
    @isTest
    static void testPublishBigDeals_EmptyList() {
        Test.startTest();
        BigDealPublisher.publishBigDeals(new List<Opportunity>());
        Test.stopTest();
        
        List<Big_Deal_Log__c> logs = [SELECT Id FROM Big_Deal_Log__c];
        System.assertEquals(0, logs.size(), 'Should handle empty list gracefully');
    }
    
    @isTest
    static void testHandleBigDealEvents_EmptyList() {
        Test.startTest();
        BigDealSubscriberHandler.handleBigDealEvents(new List<Big_Deal_Alert__e>());
        Test.stopTest();
        
        List<Big_Deal_Log__c> logs = [SELECT Id FROM Big_Deal_Log__c];
        System.assertEquals(0, logs.size(), 'Should handle empty event list gracefully');
    }
}
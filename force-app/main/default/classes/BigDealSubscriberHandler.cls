public with sharing class BigDealSubscriberHandler {
    
    public static void handleBigDealEvents(List<Big_Deal_Alert__e> bigDealEvents) {
        if (bigDealEvents == null || bigDealEvents.isEmpty()) {
            return;
        }
        
        List<Task> tasksToInsert = new List<Task>();
        List<Big_Deal_Log__c> logsToInsert = new List<Big_Deal_Log__c>();
        Set<Id> opportunityIds = new Set<Id>();
        
        for (Big_Deal_Alert__e event : bigDealEvents) {
            if (String.isNotBlank(event.Opportunity_Id__c)) {
                opportunityIds.add(event.Opportunity_Id__c);
            }
        }
        
        Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>();
        if (!opportunityIds.isEmpty()) {
            opportunityMap = new Map<Id, Opportunity>([
                SELECT Id, OwnerId, Name 
                FROM Opportunity 
                WHERE Id IN :opportunityIds
            ]);
        }
        
        for (Big_Deal_Alert__e event : bigDealEvents) {
            Opportunity opp = opportunityMap.get(event.Opportunity_Id__c);
            
            if (opp != null) {
                Task followUpTask = new Task();
                followUpTask.Subject = 'Follow up on Big Deal: ' + event.Opportunity_Name__c;
                followUpTask.Description = 'This opportunity closed for $' + event.Amount__c + 
                                          ' on ' + event.Close_Date__c + 
                                          '. Please follow up with the account to ensure customer success.';
                followUpTask.OwnerId = opp.OwnerId;
                followUpTask.WhatId = opp.Id;
                followUpTask.ActivityDate = Date.today().addDays(3);
                followUpTask.Priority = 'High';
                followUpTask.Status = 'Not Started';
                tasksToInsert.add(followUpTask);
            }
            
            Big_Deal_Log__c logRecord = new Big_Deal_Log__c();
            logRecord.Opportunity__c = event.Opportunity_Id__c;
            logRecord.Amount__c = event.Amount__c;
            logRecord.Alerted_Date__c = DateTime.now();
            logRecord.Account_Name__c = event.Account_Name__c;
            logsToInsert.add(logRecord);
        }
        
        List<Database.SaveResult> results = new List<Database.SaveResult>();
        
        if (!tasksToInsert.isEmpty()) {
            results = Database.insert(tasksToInsert, false);
            logResults(results, 'Task');
        }
        
        if (!logsToInsert.isEmpty()) {
            results = Database.insert(logsToInsert, false);
            logResults(results, 'Big_Deal_Log__c');
        }
    }
    
    private static void logResults(List<Database.SaveResult> results, String objectType) {
        for (Database.SaveResult result : results) {
            if (!result.isSuccess()) {
                for (Database.Error err : result.getErrors()) {
                    System.debug('Error inserting ' + objectType + ': ' + err.getMessage());
                }
            }
        }
    }
}
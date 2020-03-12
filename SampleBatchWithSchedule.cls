/*
*   Interface created to run a batch and reschedule in a time less than allowed by the Salesforce standard.
*/

global class SampleBatchWithSchedule implements Database.Batchable<sObject>, Database.Stateful, schedulable {
    
    // Schedulable context
    global void execute(SchedulableContext SC) {
        database.executebatch(new SampleBatchWithSchedule());
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT Id FROM SObject'
        );
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope){
        System.debug('Scope --> '+scope+' -- '+scope.size());
        
        // (Optional) Using Database.update or Database.insert with a false second parameter to allow partial processing of records on failure.
        // Documentation: https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_methods_system_database_saveresult.htm
        Database.SaveResult[] rslt = Database.update(scope, false);
    }

    global void finish(Database.BatchableContext bc){
        // (Optional) If you need to run and reschedule the batch in a short period of time,
        // this code snippet clears the completed executions and leaves the record for the next scheduled batch only
        List<CronTrigger> ct = [SELECT CronExpression, CronJobDetailId, CronJobDetail.Name, Id, State FROM CronTrigger where CronJobDetail.Name like '%SampleBatchWithSchedule%' AND State = 'DELETED'];
        if(ct.size()>0){
            for(CronTrigger cron: ct) {
                System.abortJob(cron.id);
            }
        }
        
        // (Optional) Send email after finish the batch executions
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setTargetObjectId(UserInfo.getUserId());
        mail.saveAsActivity = false;
        mail.setSubject('Schedule/Batch - SampleBatchWithSchedule ' + System.now() +' - Process Complete');
        mail.setPlainTextBody('Batch Result: Process Complete');
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });

        // In this case, this code snippet is required because is responsible by reschedule the next execution
        // You can adapt the code according to your need, every 10, 20, 30 minutes or hours
        SampleBatchWithSchedule m = new SampleBatchWithSchedule();
        datetime daterum = System.now();
        daterum = daterum.addMinutes(10);
        String day = String.valueOf(daterum.day());
        String month = String.valueOf(daterum.month());
        String year = String.valueOf(daterum.year());
        String timetoRun = '0' + ' ' + '0' + ' ' + '2' + ' ' + day + ' ' + month + ' ' + '?' + ' ' + year;
        String sch = timetoRun;
        System.debug('sch -->' + sch);
        String jobID = system.schedule('SampleBatchWithSchedule' + timetoRun, sch, m);
    }
}
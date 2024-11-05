DROP TABLE scheduler_test
/
CREATE TABLE scheduler_test (step INTEGER)
/
--
BEGIN
   --
   dbms_scheduler.create_program
     (program_name        => 'task1',
      program_type        => 'PLSQL_BLOCK',
      program_action      => 'BEGIN INSERT INTO scheduler_test VALUES (1); COMMIT; END;',
      number_of_arguments => 0,
      enabled             => FALSE);
   --
   dbms_scheduler.enable
     (name => 'task1');
   --
   dbms_scheduler.create_program
     (program_name        => 'task2',
      program_type        => 'PLSQL_BLOCK',
      program_action      => 'BEGIN INSERT INTO scheduler_test VALUES (2); COMMIT; END;',
      number_of_arguments => 0,
      enabled             => FALSE);
   --
   dbms_scheduler.enable
     (name => 'task2');
   --
   -- Create a chain for the programs to run sequentially on
   dbms_scheduler.create_chain
     (chain_name          => 'task_chain',
      rule_set_name       => NULL,
      evaluation_interval => NULL);
   --
   -- Add the jobs to the chain
   dbms_scheduler.define_chain_step
     (chain_name   =>  'task_chain',
      step_name    =>  'step1',
      program_name =>  'task1');
   --
   dbms_scheduler.define_chain_step
     (chain_name   =>  'task_chain',
      step_name    =>  'step2',
      program_name =>  'task2');
   --
   -- Define rules for running the chain steps
   dbms_scheduler.define_chain_rule
     (chain_name => 'task_chain',
      condition  => 'TRUE',
      action     => 'START step1',
      rule_name  => 'rule1');
   --
   dbms_scheduler.define_chain_rule
     (chain_name => 'task_chain',
      condition  => 'step1 COMPLETED',
      action     => 'START step2',
      rule_name  => 'rule2');
   --
   dbms_scheduler.define_chain_rule
     (chain_name => 'task_chain',
      condition  => 'step2 COMPLETED',
      action     => 'END',
      rule_name  => 'rule3');
   --
   -- Enable the chain
   dbms_scheduler.enable
     (name => 'task_chain');
   --
   -- Schedule the chain with a job
   dbms_scheduler.create_job
     (job_name      => 'test_job',
      job_type      => 'CHAIN',
      job_action    => 'task_chain',
      start_date	  => SYSDATE+1000,
      enabled       => TRUE);
--
END;
/
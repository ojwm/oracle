DECLARE
   --
   CURSOR c_objects IS
      --
      SELECT object_type,
             object_name
      FROM   user_objects
      WHERE  object_type IN ('TABLE','INDEX')
      ORDER BY object_type DESC,
               object_name ASC;
   --
   v_total_blocks              NUMBER;
   v_total_bytes               NUMBER;
   v_unused_blocks             NUMBER;
   v_unused_bytes              NUMBER;
   v_last_used_extent_file_id  NUMBER;
   v_last_used_extent_block_id NUMBER;
   v_last_used_block           NUMBER;
   --
   v_block_threshold NUMBER := 128;
--
BEGIN
   --
   -- For all objects
   FOR l_c_objects IN c_objects LOOP
      --
      BEGIN
         --
         -- Caclulate unused space
         dbms_space.unused_space
           (segment_owner             => USER,
            segment_name              => l_c_objects.object_name,
            segment_type              => l_c_objects.object_type,
            total_blocks              => v_total_blocks,
            total_bytes               => v_total_bytes,
            unused_blocks             => v_unused_blocks,
            unused_bytes              => v_unused_bytes,
            last_used_extent_file_id  => v_last_used_extent_file_id,
            last_used_extent_block_id => v_last_used_extent_block_id,
            last_used_block           => v_last_used_block,
            partition_name            => NULL);
         --
         --dbms_output.put_line('v_total_blocks             : '||v_total_blocks);
         --dbms_output.put_line('v_total_bytes              : '||v_total_bytes);
         --dbms_output.put_line('v_unused_blocks            : '||v_unused_blocks);
         --dbms_output.put_line('v_unused_bytes             : '||v_unused_bytes);
         --dbms_output.put_line('v_last_used_extent_file_id : '||v_last_used_extent_file_id);
         --dbms_output.put_line('v_last_used_extent_block_id: '||v_last_used_extent_block_id);
         --dbms_output.put_line('v_last_used_block          : '||v_last_used_block);
         --
         -- If there are enough unused blocks, try to shrink the object
         IF v_unused_blocks > v_block_threshold THEN
            --
            --dbms_output.put_line('Object name  : '||l_c_objects.object_name);
            --dbms_output.put_line('Unused blocks: '||v_unused_blocks);
            --
            -- Check whether the object can be shrunk
            BEGIN
               --
               EXECUTE IMMEDIATE 'ALTER '||l_c_objects.object_type||' '||l_c_objects.object_name||' SHRINK SPACE CHECK';
            --
            EXCEPTION
               --
               WHEN others THEN
                  --
                  -- ORA-10636: ROW MOVEMENT is not enabled
                  IF SQLCODE                 = -10636  AND
                     l_c_objects.object_type = 'TABLE' THEN
                     --
                     -- Enable row movement on the table and check whether the object can be shrunk
                     BEGIN
                        --
                        EXECUTE IMMEDIATE 'ALTER TABLE '||l_c_objects.object_name||' ENABLE ROW MOVEMENT';
                        EXECUTE IMMEDIATE 'ALTER '||l_c_objects.object_type||' '||l_c_objects.object_name||' SHRINK SPACE CHECK';
                     --
                     EXCEPTION
                        --
                        WHEN others THEN
                           --
                           -- ORA-10655: Segment can be shrunk
                           IF SQLCODE = -10655 THEN
                              --
                              EXECUTE IMMEDIATE 'ALTER '||l_c_objects.object_type||' '||l_c_objects.object_name||' SHRINK SPACE';
                           --
                           ELSE
                              --
                              dbms_output.put_line('Cannot shrink');
                           --
                           END IF;
                           --
                           EXECUTE IMMEDIATE 'ALTER TABLE '||l_c_objects.object_name||' DISABLE ROW MOVEMENT';
                     --
                     END;
                  --
                  -- ORA-10655: Segment can be shrunk
                  ELSIF SQLCODE = -10655 THEN
                     --
                     EXECUTE IMMEDIATE 'ALTER '||l_c_objects.object_type||' '||l_c_objects.object_name||' SHRINK SPACE';
                  --
                  ELSE
                     --
                     dbms_output.put_line('Cannot shrink');
                  --
                  END IF;
            --
            END;
         --
         END IF;
      --
      EXCEPTION
         --
         WHEN others THEN
            --
            NULL;
      --
      END;
   --
   END LOOP;
--
EXCEPTION
   --
   WHEN others THEN
      --
      dbms_output.put_line('Error: '||SQLERRM);
--
END;
/
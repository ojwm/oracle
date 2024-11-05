# Navigation Menu

The navigation menu is the menu that is revealed by the [hamburger button](https://en.wikipedia.org/wiki/Hamburger_button).

## List

The entries on the navigation menu are held in a list called `Navigation Menu`.

### Adding entries

* To add a new item on the navigation menu, create a new entry without a parent item.

* To add a child item to an existing item on the navigation menu, create a new entry with the parent list entry selected.

### Dynamic list

1. Go to Shared Components > Lists.

1. Create a new dynamic list with the following example SQL.

   ```sql
   SELECT level
       , label
       , target
       , NULL is_current
       , image
   FROM (
       SELECT 1 item_id, NULL parent_item_id, '1' label, APEX_PAGE.GET_URL(p_page => 1, p_clear_cache => 1) target, 'fa-number-1' image FROM dual UNION
       SELECT 2, NULL, '2', APEX_PAGE.GET_URL(p_page => 2, p_clear_cache => 2), 'fa-number-2' FROM dual UNION
       SELECT 3, NULL, '3', APEX_PAGE.GET_URL(p_page => 3, p_clear_cache => 3), 'fa-number-3' FROM dual UNION
       SELECT 4, 2, '4', APEX_PAGE.GET_URL(p_page => 4, p_clear_cache => 4), 'fa-number-4' FROM dual
   )
   START WITH parent_item_id IS NULL
   CONNECT BY PRIOR item_id = parent_item_id;
   ```

1. To use the list as the application's menu, go to the App Builder and click Edit Application Properties > User Interface.

1. Set the Navigation Menu List to the new list.

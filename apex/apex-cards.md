# APEX Cards

## Template

Cards can be rendered by using the ["Cards" template on a classic report](https://apex.oracle.com/pls/apex/r/apex_pm/ut/card-templates).

1. In Page Designer, select a region.
1. Go to the Property Editor.
1. Under the Region tab.
   * Find Identification → Type, use Classic Report.
1. Under the Attributes tab.
   * Find Appearance → Template, use Cards.

The template expects columns with specific names that populate the cards.

```sql
SELECT COUNT(*) card_title
    , d.department_name card_text
    , 'fa-building' card_icon
    , APEX_PAGE.GET_URL(
        p_page => 2
        , p_clear_cache => '1,2'
        , p_items => 'P2_DEPARTMENT_ID'
        , p_values => d.department_id
    ) card_link
FROM hr.employees e
JOIN hr.departments d ON d.department_id = e.department_id
GROUP BY d.department_id
    , d.department_name;
```

```text
CARD_TEXT              CARD_TITLE CARD_ICON      CARD_LINK                             
___________________ _____________ ______________ _____________________________________ 
Administration                  1 fa-building    f?p=:2::::1,2:P2_DEPARTMENT_ID:10     
Marketing                       2 fa-building    f?p=:2::::1,2:P2_DEPARTMENT_ID:20     
Purchasing                      6 fa-building    f?p=:2::::1,2:P2_DEPARTMENT_ID:30     
Human Resources                 1 fa-building    f?p=:2::::1,2:P2_DEPARTMENT_ID:40     
Shipping                       45 fa-building    f?p=:2::::1,2:P2_DEPARTMENT_ID:50     
IT                              5 fa-building    f?p=:2::::1,2:P2_DEPARTMENT_ID:60     
Public Relations                1 fa-building    f?p=:2::::1,2:P2_DEPARTMENT_ID:70     
Sales                          34 fa-building    f?p=:2::::1,2:P2_DEPARTMENT_ID:80     
Executive                       3 fa-building    f?p=:2::::1,2:P2_DEPARTMENT_ID:90     
Finance                         6 fa-building    f?p=:2::::1,2:P2_DEPARTMENT_ID:100    
Accounting                      2 fa-building    f?p=:2::::1,2:P2_DEPARTMENT_ID:110    

11 rows selected.
```

## Content modifiers

[Content modifiers](https://apex.oracle.com/pls/apex/r/apex_pm/ut/content-modifiers) such as `u-textCenter` can be added to the CSS classes to center the card content.

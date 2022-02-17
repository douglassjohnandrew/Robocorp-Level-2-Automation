*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the screenshot of the ordered robot.
...               Creates ZIP archive of the images.
Library           html_tables.py
Library           RPA.Archive
Library           RPA.Browser.Selenium    auto_close=${FALSE}
Library           RPA.HTTP
Library           RPA.PDF
Library           RPA.Tables

*** Keywords ***
Open the robot order website and return model info
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order
    Close the annoying modal
    Click Button When Visible    xpath://button[contains(.,'Show model info')]
    ${model_info}=    Get Element Attribute    id:model-info    outerHTML
    ${model_table}=    Read Table From Html    ${model_info}
    [Return]    ${model_table}

Get orders
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
    ${orders}=    Read table from CSV    orders.csv    header=True
    [Return]    ${orders}

Close the annoying modal
    Click Button When Visible    xpath://button[contains(.,'OK')]

Try to submit order
    Click Button    id:order
    Element Should Be Visible    id:order-another

Fill the form
    [Arguments]    ${model_table}    ${row}
    ${model_filt}=    Find Table Rows    ${model_table}    1    ==    ${row}[Head]
    ${model_row}=    Get Table Row    ${model_filt}    0
    ${part}=    Set Variable    head
    Select From List By Label    id:head    ${model_row}[${0}]${SPACE}${part}
    ${model_filt}=    Find Table Rows    ${model_table}    1    ==    ${row}[Body]
    ${model_row}=    Get Table Row    ${model_filt}    0
    ${part}=    Set Variable    body
    Click Element    xpath://label[contains(.,'${model_row}[${0}]${SPACE}${part}')]
    Input Text    xpath://label[contains(.,'3. Legs:')]/../input    ${row}[Legs]
    Input Text    id:address    ${row}[Address]

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${model_table}=    Open the robot order website and return model info
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Fill the form    ${model_table}    ${row}
        Click Button    id:preview
        Wait Until Keyword Succeeds    5x    500ms    Try to submit order
        Screenshot    id:robot-preview-image    ${CURDIR}/output/screenshots/${row}[Order number].png
        Click Button    id:order-another
        Close the annoying modal
    END
    Archive Folder With Zip    ${CURDIR}/output/screenshots    archive.zip
    [Teardown]    Close Browser

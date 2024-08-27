// Welcome to your new AL extension.
// Remember that object names and IDs should be unique across all extensions.
// AL snippets start with t*, like tpageext - give them a try and happy coding!

pageextension 50108 GLJournalBatches extends "General Journal Batches"
{
    actions
    {
        addafter("P&osting")
        //addafter(Creation)
        //addafter(ApplyData)
        {
            group(DataConversion) //Group is not mandatory
            {
                action(CurrencyConversionGLAcc)
                {
                    ApplicationArea = All;
                    Caption = 'Calculate Suggestion for Opening Entries for All G/L Accounts in Source Company';
                    ToolTip = 'Calculate Suggestion for Opening Entries for All G/L Accounts in Source Company';
                    Image = Apply;
                    Visible = ShowAdmin;
                    //Promoted = true;
                    //ShortCutKey = 'Shift+Ctrl+1';
                    trigger OnAction()
                    var
                        CurrencyConv: Codeunit "CurrencyConversion";
                    begin
                        //CurrencyConv.CurrencyConvGLEntries();
                    end;
                }
                action(CurrencyConversionBankAcc)
                {
                    ApplicationArea = All;
                    Caption = 'Calculate Suggestion for Opening Entries for All Bank Accounts in Source Company';
                    ToolTip = 'Calculate Suggestion for Opening Entries for All Bank Accounts in Source Company';
                    Image = Apply;
                    Visible = ShowAdmin;
                    //Promoted = true;
                    //ShortCutKey = 'Shift+Ctrl+2';
                    trigger OnAction()
                    var
                        CurrencyConv: Codeunit "CurrencyConversion";
                    begin
                        //CurrencyConv.CurrencyConvGLEntries();
                    end;
                }
            }
        }

        /*
        addafter(ApplyData_Promoted)
        {
            actionref("Currency Conversions"; CurrencyConversion)
            {
            }
        }
        */
    }
    trigger OnOpenPage()
    begin
        ShowAdmin := GenMgt.IsAdminUser;
        ////ShowAdmin := true;
        //Message(UserId); ////
    end;

    var
        GenMgt: Codeunit GeneralMgt;
        ShowAdmin: Boolean;
}
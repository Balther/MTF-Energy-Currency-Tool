// Welcome to your new AL extension.
// Remember that object names and IDs should be unique across all extensions.
// AL snippets start with t*, like tpageext - give them a try and happy coding!

pageextension 50111 IntSynchErrorList extends "Integration Synch. Error List"
{
    actions
    {
        addafter(DataIntegrationSynchronizeNow)
        {
            group(Delete)
            {
                action(DeleteAll)
                {
                    ApplicationArea = Suite;
                    Caption = 'Delete All Error Log Entries (Table Level)';
                    //Enabled = HasRecords;
                    Visible = Showadmin;
                    Image = Delete;
                    ToolTip = 'Delete all error log information for job queue entries (Table Level).';
                    Promoted = false;

                    trigger OnAction()
                    begin
                        ////ShowAdmin := GenMgt.IsAdminUser;
                        //Rec.DeleteEntries(0);
                        rec.deleteall(true);
                    end;
                }
                action(DeleteAllwCommit)
                {
                    ApplicationArea = Suite;
                    Caption = 'Delete All Error Log Entries with Commit (Record Level)';
                    //Enabled = HasRecords;
                    Visible = Showadmin;
                    Image = Delete;
                    ToolTip = 'Delete all error log information for job queue entries with Commit (Record Level).';
                    Promoted = false;

                    trigger OnAction()
                    begin
                        ////ShowAdmin := GenMgt.IsAdminUser;
                        //Rec.DeleteEntries(0);

                        i := 0;
                        WindowDialog.Open(CountTxt + '\\' + ProgressBar);
                        //Rec.setrange("Account Type", Rec."Account Type"::Posting);
                        if Rec.FindSet() then begin
                            TotalRecords := Rec.CountApprox;
                            repeat
                                i += 1;
                                if (i < 100) or (i MOD 10000 = 0) then begin
                                    WindowDialog.update(1, format(i) + ' / ' + format(TotalRecords) + ' :: ' + format(Rec."No."));
                                    WindowDialog.Update(2, (i / TotalRecords * 10000) DIV 1);
                                    Commit; //THE REAL SHIT
                                end;

                                rec.delete; //THE SHIT

                            until rec.next = 0;
                        end;
                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        ////ShowAdmin := GenMgt.IsAdminUser;
        ShowAdmin := true; ////
    end;

    var
        GenMgt: Codeunit GeneralMgt;
        ShowAdmin: Boolean;
        WindowDialog: Dialog;
        i: Integer;
        TotalRecords: Integer;
        CountTxt: Label 'Counting: @2@@@@@@@@@';
        ProgressBar: Label 'Progressing: #1##########';
        ShowProgressTxt: Label 'X';
}
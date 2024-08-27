codeunit 50105 CurrencyConversion

{
    //Currency Setups
    procedure CurrencyConvGLEntries(GJL: Record "Gen. Journal Line") //(Currency: Record Currency)
    var
        //Journals
        //GJL: Record "Gen. Journal Line";
        GJLOld: Record "Gen. Journal Line";
        GJLSource: Record "Gen. Journal Line";

        //Data Tables
        GLAcc: Record "G/L Account";
        GLAccSource: Record "G/L Account";
        DirectPostingDeactivated: Boolean;

        DocNoSet: Code[20];
        PostingDateSet: Date;
    begin
        GenMgt.CheckAdminUser();

        //MFTSetup.get;
        MFTSetup.FindFirst(); ////WHY does GET suddenly not work?

        MFTSetup.TestField(SourceCompany);
        MFTSetup.TestField(DocumentNo);
        MFTSetup.TestField(CutOffDate);
        //Set Global Values
        //DocNoSet := DocNoSetGlobal;
        SourceCompany := MFTSetup.SourceCompany;
        DocNoSet := MFTSetup.DocumentNo;
        //GJLOld.get(GJL."Journal Template Name", gjl."Journal Batch Name", GJL."Line No.");
        if GJL."Posting Date" = 0D then
            PostingDateSet := WorkDate()
        else
            PostingDateSet := GJL."Posting Date";

        GJLOld := GJL;
        IF (GJLOLD."Account No." = '') and not gjlold.IsEmpty then
            GJLOLD.Delete();

        i := 0;
        j := 0;
        WindowDialog.Open(CountTxt + '\\' + ProgressBar);
        ////WindowDialog.Open(ProgressBar);

        GLSetupSource.ChangeCompany(SourceCompany); //DO PARAMETER SETUP
        GLSetupSource.get;
        GLSetupSource.TestField("LCY Code");
        BaseCurrencySource := GLSetupSource."LCY Code";
        GJLSource.ChangeCompany(SourceCompany); //DO PARAMETER SETUP               

        GLAccSource.ChangeCompany(SourceCompany); //DO PARAMETER SETUP
        //GLAccSource.CalcFields(Balance);
        //GLAccSource.setfilter(Balance,'<>0');
        GLAccSource.setrange("Account Type", GLAccSource."Account Type"::Posting);
        if GLAccSource.FindSet() then begin
            TotalRecords := GLAccSource.CountApprox;
            repeat
                i += 1;
                ////if (i < 100) or (i MOD 100 = 0) then begin
                WindowDialog.Update(2, (i / TotalRecords * 10000) DIV 1);
                //TxtBuilder.Append(ShowProgressTxt);
                //WindowDialog.update(2, TxtBuilder.ToText());
                WindowDialog.update(1, format(i) + ' / ' + format(TotalRecords) + ' :: ' + format(GLAccSource."No."));
                ////end;

                //Direct Posting Handling
                /// GJL (local event): procedure OnBeforeCheckDirectPosting(var GLAccount: Record "G/L Account"; var IsHandled: Boolean; GenJournalLine: Record "Gen. Journal Line")
                GLAcc.get(GLAccSource."No.");
                DirectPostingDeactivated := false;
                If GLAcc."Direct Posting" = false then begin
                    DirectPostingDeactivated := true;
                    GLAcc."Direct Posting" := true;
                    GLAcc.modify;
                end;

                GLAccSource.SetFilter("Date Filter", '..%1', MFTSetup.CutOffDate);
                GLAccSource.CalcFields("Balance at Date");
                if GLAccSource."Balance at Date" <> 0 then begin
                    j += 1;

                    //JOURNAL
                    /////////////////////////********************PERHAPS CHANGE TO JOURNAL and use line data from chosen journal
                    //GJL.validate("Journal Batch Name", 'STANDARD'); //ENU: DEFAULT / DAN: STANDARD
                    //GJL.validate("Journal Template Name", 'AKTIVER'); //ENU: GENERAL / DAN: GENERELT

                    ////GJL."Journal Template Name" := 'AKTIVER'; //ENU: GENERAL / DAN: GENERELT
                    ////GJL."Journal Batch Name" := 'STANDARD'; //ENU: DEFAULT / DAN: STANDARD

                    GJL."Journal Template Name" := GJL."Journal Template Name";
                    //if gjl."Journal Template Name" = '' then
                    //    GJL."Journal Template Name" := 'AKTIVER'; //ENU: GENERAL / DAN: GENERELT
                    GJL."Journal Batch Name" := GJL."Journal Batch Name";
                    // if GJL."Journal Batch Name" = '' then
                    //     GJL."Journal Batch Name" := 'STANDARD'; //ENU: DEFAULT / DAN: STANDARD

                    GJL.validate("Line No.", 10000 * j);

                    //GL ACCOUNT
                    GJL.validate("Account Type", GJL."Account Type"::"G/L Account");
                    GJL.Validate("Account No.", GLAccSource."No.");

                    //DETAILS
                    GJL.Validate("Document No.", DocNoSet);
                    GJL.Validate("Posting Date", PostingDateSet);
                    GJL.validate("Currency Code", BaseCurrencySource);
                    GJL.Validate(Amount, GLAccSource."Balance at Date");

                    //DIMENSIONS /SPLIT
                    //GJL.CreateDim();

                    //BLANK POSTING GROUPS etc. to make posting balance
                    GJL.validate("Gen. Bus. Posting Group", '');
                    GJL.Validate("Gen. Prod. Posting Group", '');
                    GJL.validate("Bal. Gen. Bus. Posting Group", '');
                    GJL.Validate("Bal. Gen. Prod. Posting Group", '');

                    GJL.Insert(true);

                    /////
                    //Create Balance Close in Source Company
                    /////
                    ResetSourcePosting := true;
                    if ResetSourcePosting then begin
                        GJLSource."Journal Template Name" := GJL."Journal Template Name";
                        GJLSource."Journal Batch Name" := GJL."Journal Batch Name";

                        GJLSource.validate("Line No.", 10000 * j);

                        //GL ACCOUNT
                        GJLSource.validate("Account Type", GJL."Account Type"::"G/L Account");
                        GJLSource.Validate("Account No.", GLAccSource."No.");

                        //DETAILS
                        GJLSource.Validate("Document No.", DocNoSet);
                        GJLSource.Validate("Posting Date", PostingDateSet);
                        GJLSource.validate("Currency Code", BaseCurrencySource);
                        GJLSource.Validate(Amount, GLAccSource."Balance at Date" * -1);
                        GJLSource.Validate("Amount (LCY)", GJLSource.Amount); ////

                        //DIMENSIONS /SPLIT
                        //GJL.CreateDim();

                        //BLANK POSTING GROUPS etc. to make posting balance
                        GJLSource.validate("Gen. Bus. Posting Group", '');
                        GJLSource.Validate("Gen. Prod. Posting Group", '');
                        GJLSource.validate("Bal. Gen. Bus. Posting Group", '');
                        GJLSource.Validate("Bal. Gen. Prod. Posting Group", '');

                        //GJLSource.Insert(true);
                        GJLSource.Insert;
                    end;
                end;

            //if DirectPostingDeactivated then begin
            //    GLAcc."Direct Posting" := false;
            //    GLAcc.modify;
            //end;
            until GLAccSource.Next = 0;
        end;

        /*
        if Currency.FindSet() then begin
            TotalRecords := Currency.CountApprox;
            repeat
                i += 1;
                if (i < 100) or (i MOD 100 = 0) then begin
                    WindowDialog.Update(2, (i / TotalRecords * 10000) DIV 1);
                    //TxtBuilder.Append(ShowProgressTxt);
                    //WindowDialog.update(2, TxtBuilder.ToText());
                    WindowDialog.update(1, format(i) + ' / ' + format(TotalRecords) + ' :: ' + format(Currency.Code));
                end;

            // If Currency.Code = '' then begin
            //     Currency.validate(Code, 'DKK');
            //     //Currency.Validate(Code, 'EUR');
            //     Currency.modify;
            // end;
            until Currency.Next = 0;
        end;
        */
        WindowDialog.Close();
        //Message(format(Item2));
    end;

    procedure CurrencyConvVendLegdEntries(GJL: Record "Gen. Journal Line") //(Currency: Record Currency)
    var
        //Journals
        //GJL: Record "Gen. Journal Line";
        GJLOld: Record "Gen. Journal Line";

        //Data Tables
        Vend: Record Vendor;
        VendSource: Record Vendor;
        VendLESource: Record "Vendor Ledger Entry";
        VendPostGrp: Record "Vendor Posting Group";

        DocNoSet: Code[20];
        PostingDateSet: Date;
    begin
        GenMgt.CheckAdminUser();

        //MFTSetup.get;
        MFTSetup.FindFirst(); ////WHY does GET suddenly not work?

        MFTSetup.TestField(SourceCompany);
        MFTSetup.TestField(DocumentNo);
        MFTSetup.TestField(CutOffDate);
        //Set Global Values
        //DocNoSet := DocNoSetGlobal;
        SourceCompany := MFTSetup.SourceCompany;
        DocNoSet := MFTSetup.DocumentNo;

        //GJLOld.get(GJL."Journal Template Name", gjl."Journal Batch Name", GJL."Line No.");
        if GJL."Posting Date" = 0D then
            PostingDateSet := WorkDate()
        else
            PostingDateSet := GJL."Posting Date";

        GJLOld := GJL;
        IF (GJLOLD."Account No." = '') and not gjlold.IsEmpty then
            GJLOLD.Delete();

        i := 0;
        j := 0;
        WindowDialog.Open(CountTxt + '\\' + ProgressBar);
        ////WindowDialog.Open(ProgressBar);

        GLSetupSource.ChangeCompany(SourceCompany); //DO PARAMETER SETUP
        GLSetupSource.get;
        GLSetupSource.TestField("LCY Code");
        BaseCurrencySource := GLSetupSource."LCY Code";

        VendSource.ChangeCompany(SourceCompany); //DO PARAMETER SETUP
        VendLESource.ChangeCompany(SourceCompany); //DO PARAMETER SETUP
        //VendSource.CalcFields(Balance);
        //VendSource.setfilter(Balance,'<>0');
        //VendSource.setrange("Account Type", VendSource."Account Type"::Posting);
        if VendSource.FindSet() then begin
            TotalRecords := VendSource.CountApprox;
            repeat
                i += 1;
                ////if (i < 100) or (i MOD 100 = 0) then begin
                WindowDialog.Update(2, (i / TotalRecords * 10000) DIV 1);
                WindowDialog.update(1, format(i) + ' / ' + format(TotalRecords) + ' :: ' + format(VendSource."No."));
                ////end;

                //Direct Posting Handling
                /// GJL (local event): procedure OnBeforeCheckDirectPosting(var GLAccount: Record "G/L Account"; var IsHandled: Boolean; GenJournalLine: Record "Gen. Journal Line")

                VendSource.SetFilter("Date Filter", '..%1', MFTSetup.CutOffDate);
                //VendSource.CalcFields(Balance);
                VendSource.CalcFields("Net Change");
                //if VendSource.Balance <> 0 then begin
                if VendSource."Net Change" <> 0 then begin
                    VendLESource.setrange(Open, true);
                    VendLESource.SetRange("Vendor No.", VendSource."No.");
                    VendLESource.SetRange("Posting Date", 0D, MFTSetup.CutOffDate);
                    VendLESource.SetFilter("Date Filter", '..%1', MFTSetup.CutOffDate);
                    if VendLESource.FindSet() then begin
                        repeat
                            j += 1;

                            Vend.get(VendSource."No."); ////****CHECK IF ACCOUNT DIFFERENCES

                            GJL."Journal Template Name" := GJL."Journal Template Name";
                            GJL."Journal Batch Name" := GJL."Journal Batch Name";

                            GJL.validate("Line No.", 10000 * j);

                            //VENDOR ACCOUNT
                            GJL.validate("Account Type", GJL."Account Type"::Vendor);
                            ////GJL.Validate("Account No.", VendSource."No.");
                            GJL."Account No." := VendSource."No."; //////
                            GJL.validate("Bal. Account Type", GJL."Bal. Account Type"::"G/L Account");
                            VendPostGrp.get(Vend."Vendor Posting Group");
                            GJL.validate("Bal. Account No.", VendPostGrp."Payables Account");

                            //DETAILS
                            GJL.validate("Document Type", VendLESource."Document Type");
                            //GJL.Validate("Document No.", DocNoSet);
                            GJL.Validate("Document No.", VendLESource."Document No.");
                            GJL.Validate("Document Date", VendLESource."Document Date");
                            GJL.Validate("Posting Date", PostingDateSet);
                            GJL.validate("Due Date", VendLESource."Due Date");
                            GJL.Validate("External Document No.", VendLESource."External Document No.");
                            ///GJL.validate("Currency Code", BaseCurrencySource);

                            //AMOUNTS
                            if VendLESource."Currency Code" = '' then
                                GJL.validate("Currency Code", BaseCurrencySource)
                            else
                                GJL.validate("Currency Code", VendLESource."Currency Code");
                            ////GJL.Validate(Amount, VendSource.Balance); //Vendor Balance Without Split
                            VendLESource.CalcFields(Amount);
                            GJL.Validate(Amount, VendLESource.Amount); //Vendor Balance With Split (Check for partly applied amounts)***

                            //DIMENSIONS /SPLIT
                            //GJL.CreateDim();

                            //BLANK POSTING GROUPS etc. to make posting balance
                            GJL.validate("Gen. Bus. Posting Group", '');
                            GJL.Validate("Gen. Prod. Posting Group", '');
                            GJL.validate("Bal. Gen. Bus. Posting Group", '');
                            GJL.Validate("Bal. Gen. Prod. Posting Group", '');

                            GJL.Insert(true);
                        until VendLESource.next = 0;
                    end;

                end;
            until VendSource.Next = 0;
        end;
        WindowDialog.Close();
    end;

    procedure CurrencyConvBankEntries(GJL: Record "Gen. Journal Line") //(Currency: Record Currency)
    var
        //Journals
        //GJL: Record "Gen. Journal Line";
        GJLOld: Record "Gen. Journal Line";

        //Data Tables
        BankAcc: Record "Bank Account";
        BankAccSource: Record "Bank Account";
        BankLESource: Record "Bank Account Ledger Entry";
        BankPostGrp: Record "Bank Account Posting Group";

        DocNoSet: Code[20];
        PostingDateSet: Date;
    begin
        GenMgt.CheckAdminUser();

        //MFTSetup.get;
        MFTSetup.FindFirst(); ////WHY does GET suddenly not work?

        MFTSetup.TestField(SourceCompany);
        MFTSetup.TestField(DocumentNo);
        MFTSetup.TestField(CutOffDate);
        //Set Global Values
        //DocNoSet := DocNoSetGlobal;
        SourceCompany := MFTSetup.SourceCompany;
        DocNoSet := MFTSetup.DocumentNo;
        //GJLOld.get(GJL."Journal Template Name", gjl."Journal Batch Name", GJL."Line No.");
        if GJL."Posting Date" = 0D then
            PostingDateSet := WorkDate()
        else
            PostingDateSet := GJL."Posting Date";

        GJLOld := GJL;
        IF (GJLOLD."Account No." = '') and not gjlold.IsEmpty then
            GJLOLD.Delete();

        i := 0;
        j := 0;
        WindowDialog.Open(CountTxt + '\\' + ProgressBar);
        ////WindowDialog.Open(ProgressBar);

        GLSetupSource.ChangeCompany(SourceCompany); //DO PARAMETER SETUP
        GLSetupSource.get;
        GLSetupSource.TestField("LCY Code");
        BaseCurrencySource := GLSetupSource."LCY Code";

        BankAccSource.ChangeCompany(SourceCompany); //DO PARAMETER SETUP
        BankLESource.ChangeCompany(SourceCompany); //DO PARAMETER SETUP
        //VendSource.CalcFields(Balance);
        //VendSource.setfilter(Balance,'<>0');
        //VendSource.setrange("Account Type", VendSource."Account Type"::Posting);
        //BankAccSource.SetAutoCalcFields(Balance);
        if BankAccSource.FindSet() then begin
            TotalRecords := BankAccSource.CountApprox;
            repeat
                i += 1;
                ////if (i < 100) or (i MOD 100 = 0) then begin
                WindowDialog.Update(1, format(i) + ' / ' + format(TotalRecords) + ' :: ' + format(BankAccSource."No."));
                WindowDialog.Update(2, (i / TotalRecords * 10000) DIV 1);
                ////end;

                //Direct Posting Handling
                /// GJL (local event): procedure OnBeforeCheckDirectPosting(var GLAccount: Record "G/L Account"; var IsHandled: Boolean; GenJournalLine: Record "Gen. Journal Line")

                BankAccSource.SetFilter("Date Filter", '..%1', MFTSetup.CutOffDate);
                BankAccSource.CalcFields("Balance at Date");
                if BankAccSource."Balance at Date" <> 0 then begin
                    BankAcc.get(BankAccSource."No."); ////****CHECK IF ACCOUNT DIFFERENCES

                    //Error(format(BankAccSource."No.") + ' :: ' + format(BankAccSource."Balance at Date"));
                    if BankAcc.Blocked then begin
                        BankAcc.Blocked := false;
                        BankAcc.modify;
                    end;

                    if MFTSetup.BankEntryLevel then begin
                        BankLESource.setrange(Open, true);
                        BankLESource.SetRange("Bank Account No.", BankAccSource."No.");
                        BankLESource.setrange("Posting Date", 0D, MFTSetup.CutOffDate);
                        if BankLESource.FindSet() then begin
                            repeat
                                CreateBankAccJnlLine(GJL, BankAcc, BankAccSource, MFTSetup.BankEntryLevel, BankLESource, PostingDateSet, DocNoSet);
                                /////Split Balancing Account Posting into Separate Journal Line
                                //Balancing Posting (Makes Currency Error, if in same line as Balancing Account)
                                If MFTSetup.SplitBalAccToSeparateLine then
                                    CreateBalancingBankAccJnlLine(GJL, BankAcc, BankAccSource, MFTSetup.BankEntryLevel, BankLESource, PostingDateSet, DocNoSet);
                            until BankLESource.next = 0;
                        end;
                    end else begin
                        CreateBankAccJnlLine(GJL, BankAcc, BankAccSource, MFTSetup.BankEntryLevel, BankLESource, PostingDateSet, DocNoSet);
                        If MFTSetup.SplitBalAccToSeparateLine then begin
                            CreateBalancingBankAccJnlLine(GJL, BankAcc, BankAccSource, MFTSetup.BankEntryLevel, BankLESource, PostingDateSet, DocNoSet);
                        end;
                    end;
                end;
            until BankAccSource.Next = 0;
        end;
        WindowDialog.Close();
    end;

    procedure CreateBankAccJnlLine(var GJL: Record "Gen. Journal Line"; BankAcc: Record "Bank Account"; BankAccSource: Record "Bank Account"; BankEntryLevel: Boolean; BankLESource: Record "Bank Account Ledger Entry"; PostingDateSet: Date; DocNoSet: Code[20])
    var
        BankPostGrp: Record "Bank Account Posting Group";
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        //Error(format(BankAccSource."No.") + ' :: ' + format(BankAccSource."Balance at Date"));
        j += 1;

        GJL."Journal Template Name" := GJL."Journal Template Name";
        GJL."Journal Batch Name" := GJL."Journal Batch Name";

        GJL.validate("Line No.", 10000 * j);

        //BANK ACCOUNT
        GJL.validate("Account Type", GJL."Account Type"::"Bank Account");
        GJL.Validate("Account No.", BankAccSource."No.");

        //Balancing Posting (Makes Currency Error, if in same line as Balancing Account) (see later separate line)
        if not MFTSetup.SplitBalAccToSeparateLine then begin
            GJL.validate("Bal. Account Type", GJL."Bal. Account Type"::"G/L Account");
            BankPostGrp.get(BankAcc."Bank Acc. Posting Group");
            GJL.validate("Bal. Account No.", BankPostGrp."G/L Account No.");
        end;

        If BankEntryLevel then begin
            //DETAILS
            GJL.validate("Document Type", BankLESource."Document Type");
            //GJL.Validate("Document No.", DocNoSet);
            GJL.Validate("Document No.", BankLESource."Document No.");
            GJL.Validate("Document Date", BankLESource."Document Date");
            GJL.Validate("Posting Date", PostingDateSet);
            //GJL.validate("Due Date", BankLESource."Due Date");
            //GJL.Validate("External Document No.", BankLESource."External Document No.");
            ///GJL.validate("Currency Code", BaseCurrencySource);

            //AMOUNTS

            if BankLESource."Currency Code" = '' then
                GJL.validate("Currency Code", BaseCurrencySource)
            else
                GJL.validate("Currency Code", BankLESource."Currency Code");
            ////GJL.Validate(Amount, VendSource.Balance); //Vendor Balance Without Split
            //BankLESource.CalcFields(Amount);
            GJL.Validate(Amount, BankLESource.Amount); //Vendor Balance With Split (Check for partly applied amounts)***

            //DIMENSIONS /SPLIT
            //GJL.CreateDim();
        end else begin
            //DETAILS
            GJL.validate("Document Type", gjl."Document Type"::" ");
            GJL.Validate("Document No.", DocNoSet);
            //GJL.Validate("Document Date", BankLESource."Document Date");
            GJL.Validate("Posting Date", PostingDateSet);
            //GJL.validate("Currency Code", BaseCurrencySource);

            //AMOUNTS
            if BankAccSource."Currency Code" = '' then begin
                if BankAcc."Currency Code" = '' then
                    BankAcc.validate("Currency Code", BaseCurrencySource);
                // if BankAccSource."No." = 'SAL-0021' then
                //     GJL.validate("Currency Code", BankAcc."Currency Code")
                // else
                //     GJL.validate("Currency Code", BaseCurrencySource);
                ////GJL.Validate(Amount, VendSource.Balance); //Vendor Balance Without Split
                //BankLESource.CalcFields(Amount);
            end;
            GJL.validate("Currency Code", BankAcc."Currency Code");
            // if BankAccSource."No." = 'SAL-0021' then
            //     GJL.Validate(Amount, CurrExchRate.ExchangeAmount(BankAccSource."Balance at Date", BaseCurrencySource, BankAcc."Currency Code", gjl."Posting Date")) //Convert Amount from EUR to DKK as Bank Account has changed Currency
            // else
            //     GJL.Validate(Amount, BankAccSource."Balance at Date"); //Vendor Balance With Split (Check for partly applied amounts)***
            if ((BankAcc."Currency Code" = BankAccSource."Currency Code") or ((BankAccSource."Currency Code" = '') and (BankAcc."Currency Code" = BaseCurrencySource))) then
                GJL.Validate(Amount, BankAccSource."Balance at Date") //Vendor Balance With Split (Check for partly applied amounts)***
            else begin
                if BankAccSource."Currency Code" = '' then
                    GJL.Validate(Amount, CurrExchRate.ExchangeAmount(BankAccSource."Balance at Date", BaseCurrencySource, BankAcc."Currency Code", gjl."Posting Date")) //Convert Amount from EUR to DKK as Bank Account has changed Currency
                else
                    GJL.Validate(Amount, CurrExchRate.ExchangeAmount(BankAccSource."Balance at Date", BankAccSource."Currency Code", BankAcc."Currency Code", gjl."Posting Date")); //Convert Amount from EUR to DKK as Bank Account has changed Currency
            end;
        end;

        //BLANK POSTING GROUPS etc. to make posting balance
        GJL.validate("Gen. Bus. Posting Group", '');
        GJL.Validate("Gen. Prod. Posting Group", '');
        GJL.validate("Bal. Gen. Bus. Posting Group", '');
        GJL.Validate("Bal. Gen. Prod. Posting Group", '');

        GJL.Insert(true);
    end;

    procedure CreateBalancingBankAccJnlLine(var GJL: Record "Gen. Journal Line"; BankAcc: Record "Bank Account"; BankAccSource: Record "Bank Account"; BankEntryLevel: Boolean; BankLESource: Record "Bank Account Ledger Entry"; PostingDateSet: Date; DocNoSet: Code[20])
    var
        BankPostGrp: Record "Bank Account Posting Group";
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        GJL.validate("Line No.", GJL."Line No." + 10);
        GJL.validate("Account Type", GJL."Bal. Account Type"::"G/L Account");
        BankPostGrp.get(BankAcc."Bank Acc. Posting Group");
        GJL.validate("Account No.", BankPostGrp."G/L Account No.");

        If BankEntryLevel then begin
            //DETAILS
            GJL.validate("Document Type", BankLESource."Document Type");
            //GJL.Validate("Document No.", DocNoSet);
            GJL.Validate("Document No.", BankLESource."Document No.");
            GJL.Validate("Document Date", BankLESource."Document Date");
            GJL.Validate("Posting Date", PostingDateSet);
            //GJL.validate("Due Date", BankLESource."Due Date");
            GJL.Validate("External Document No.", BankLESource."External Document No.");
            ///GJL.validate("Currency Code", BaseCurrencySource);

            //AMOUNTS
            if BankLESource."Currency Code" = '' then
                GJL.validate("Currency Code", BaseCurrencySource)
            else
                GJL.validate("Currency Code", BankLESource."Currency Code");
            ////GJL.Validate(Amount, VendSource.Balance); //Vendor Balance Without Split
            //BankLESource.CalcFields(Amount);
            GJL.Validate(Amount, -BankLESource.Amount); //Vendor Balance With Split (Check for partly applied amounts)***

            //DIMENSIONS /SPLIT
            //GJL.CreateDim();
        end else begin
            //DETAILS
            GJL.validate("Document Type", GJL."Document Type"::" ");
            GJL.Validate("Document No.", DocNoSet);
            //GJL.Validate("Document Date", BankLESource."Document Date");
            GJL.Validate("Posting Date", PostingDateSet);
            //GJL.validate("Due Date", BankLESource."Due Date");
            //GJL.Validate("External Document No.", BankLESource."External Document No.");
            ///GJL.validate("Currency Code", BaseCurrencySource);

            //AMOUNTS
            // if BankAccSource."Currency Code" = '' then begin
            //     if BankAccSource."No." = 'SAL-0021' then
            //         GJL.validate("Currency Code", BankAcc."Currency Code")
            //     else
            //         GJL.validate("Currency Code", BaseCurrencySource);
            // end else
            //     GJL.validate("Currency Code", BankAccSource."Currency Code");
            // ////GJL.Validate(Amount, VendSource.Balance); //Vendor Balance Without Split
            // //BankLESource.CalcFields(Amount);
            // if BankAccSource."No." = 'SAL-0021' then
            //     GJL.Validate(Amount, CurrExchRate.ExchangeAmount(-BankAccSource."Balance at Date", BaseCurrencySource, BankAcc."Currency Code", gjl."Posting Date")) //Convert Amount from EUR to DKK as Bank Account has changed Currency
            // else
            //     GJL.Validate(Amount, -BankAccSource."Balance at Date"); //Vendor Balance With Split (Check for partly applied amounts)***
            if BankAccSource."Currency Code" = '' then begin
                if BankAcc."Currency Code" = '' then
                    BankAcc.validate("Currency Code", BaseCurrencySource);
            end;
            GJL.validate("Currency Code", BankAcc."Currency Code");
            if ((BankAcc."Currency Code" = BankAccSource."Currency Code") or ((BankAccSource."Currency Code" = '') and (BankAcc."Currency Code" = BaseCurrencySource))) then
                GJL.Validate(Amount, -BankAccSource."Balance at Date") //Vendor Balance With Split (Check for partly applied amounts)***
            else begin
                if BankAccSource."Currency Code" = '' then
                    GJL.Validate(Amount, CurrExchRate.ExchangeAmount(-BankAccSource."Balance at Date", BaseCurrencySource, BankAcc."Currency Code", gjl."Posting Date")) //Convert Amount from EUR to DKK as Bank Account has changed Currency
                else
                    GJL.Validate(Amount, CurrExchRate.ExchangeAmount(-BankAccSource."Balance at Date", BankAccSource."Currency Code", BankAcc."Currency Code", gjl."Posting Date")); //Convert Amount from EUR to DKK as Bank Account has changed Currency
            end;

            //DIMENSIONS /SPLIT
            //GJL.CreateDim();
        end;

        //BLANK POSTING GROUPS etc. to make posting balance
        GJL.validate("Gen. Bus. Posting Group", '');
        GJL.Validate("Gen. Prod. Posting Group", '');
        GJL.validate("Bal. Gen. Bus. Posting Group", '');
        GJL.Validate("Bal. Gen. Prod. Posting Group", '');

        GJL.Insert(true);
    end;

    var
        GenMgt: Codeunit GeneralMgt;
        WindowDialog: Dialog;
        i: Integer;
        j: Integer;
        TotalRecords: Integer;
        CountTxt: Label 'Counting: @2@@@@@@@@@';
        ProgressBar: Label 'Progressing: #1##########';
        ShowProgressTxt: Label 'X';
        TxtBuilder: TextBuilder;
        //Setups
        GLSetupSource: Record "General Ledger Setup";
        BaseCurrencySource: Code[10];
        ResetSourcePosting: Boolean;

        MFTSetup: Record "MFT - General Setup";
        //SourceCompany: Label 'MFT Energy PTE. LTD.';
        ////SourceCompany: Label 'MFT Energy Singapore PTE. LTD.';
        SourceCompany: Text[30];
    ////DocNoSetGlobal: label 'OPENING2024';

}

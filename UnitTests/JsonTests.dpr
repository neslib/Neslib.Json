program JsonTests;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.TestFramework,
  Tests.Neslib.Json.IO in 'Tests\Tests.Neslib.Json.IO.pas',
  Neslib.Json in '..\Neslib.Json.pas',
  TestUtils in 'TestUtils.pas',
  Tests.Neslib.Json in 'Tests\Tests.Neslib.Json.pas',
  Neslib.Json.IO in '..\Neslib.Json.IO.pas',
  Neslib.Json.Path in '..\Neslib.Json.Path.pas',
  Tests.Neslib.Json.Path in 'Tests\Tests.Neslib.Json.Path.pas';

var
  Runner: ITestRunner;
  Results: IRunResults;
  Logger: ITestLogger;
begin
  try
    ReportMemoryLeaksOnShutdown := True;

    // Check command line options, will exit if invalid
    TDUnitX.CheckCommandLine;

    // Create the test runner
    Runner := TDUnitX.CreateRunner;

    // Tell the runner to use RTTI to find Fixtures
    Runner.UseRTTI := True;

    // Tell the runner how we will log things
    // Log to the console window
    Logger := TDUnitXConsoleLogger.Create(True);
    Runner.AddLogger(Logger);

    // Run tests
    Results := Runner.Execute;
    if (not Results.AllPassed) then
      System.ExitCode := EXIT_ERRORS;

    if (TDUnitX.Options.ExitBehavior = TDUnitXExitBehavior.Pause) then
    begin
      System.Write('Done.. press <Enter> key to quit.');
      System.Readln;
    end;
  except
    on E: Exception do
      System.Writeln(E.ClassName, ': ', E.Message);
  end;
end.

# Cópia de godot-port\esconder-janela.ps1 com uma diferença: não mexe nos Godot que já estavam abertos quando ele começou
# (a janela "Vagrant sala (Godot)" do Fernando fica onde está). Uso: esconder-janela-agua.ps1 <segundos>
Add-Type @'
using System;using System.Runtime.InteropServices;using System.Collections.Generic;
public class J{public delegate bool CB(IntPtr h,IntPtr p);
[DllImport("user32.dll")]static extern bool EnumWindows(CB f,IntPtr p);
[DllImport("user32.dll")]static extern uint GetWindowThreadProcessId(IntPtr h,out uint pid);
[DllImport("user32.dll")]static extern bool IsWindowVisible(IntPtr h);
[DllImport("user32.dll")]static extern bool SetWindowPos(IntPtr h,IntPtr a,int x,int y,int cx,int cy,uint f);
[DllImport("user32.dll")]static extern bool GetWindowRect(IntPtr h,out R r);
public struct R{public int L,T,Ri,B;}
public static int Empurra(HashSet<uint> ids){int n=0;EnumWindows((h,p)=>{uint pid;GetWindowThreadProcessId(h,out pid);
 if(ids.Contains(pid)&&IsWindowVisible(h)){R r;GetWindowRect(h,out r);if(r.L<10000){SetWindowPos(h,IntPtr.Zero,20000,0,0,0,0x0001|0x0004|0x0010);n++;}}return true;},IntPtr.Zero);return n;}}
'@
$antes = @(Get-Process Godot_v4* -ErrorAction SilentlyContinue | % { $_.Id })
$fim = (Get-Date).AddSeconds([int]$args[0])
while ((Get-Date) -lt $fim) {
  $ids = New-Object 'System.Collections.Generic.HashSet[uint32]'
  Get-Process Godot_v4* -ErrorAction SilentlyContinue | ? { $_.ProcessName -notlike '*console*' -and $antes -notcontains $_.Id } | % { [void]$ids.Add([uint32]$_.Id) }
  if ($ids.Count) { [void][J]::Empurra($ids) }
  Start-Sleep -Milliseconds 50
}

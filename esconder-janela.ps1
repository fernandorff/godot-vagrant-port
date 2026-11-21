# Enquanto houver Godot rodando, empurra as janelas dele para fora de todos os monitores (x=20000) sem ativar.
# O Godot puxa o --position de volta para a tela; o Windows aceita a posição fora quando ela vem de fora (como a do Chrome em -5000).
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
$fim = (Get-Date).AddSeconds([int]$args[0])
while ((Get-Date) -lt $fim) {
  $ids = New-Object 'System.Collections.Generic.HashSet[uint32]'
  # só as rodadas automáticas (--saida= ou --png= na linha de comando): a janela que o Fernando abre para ver fica onde está
  Get-CimInstance Win32_Process -Filter "Name LIKE 'Godot%'" -ErrorAction SilentlyContinue | ? { $_.CommandLine -match '--(saida|png)=' } | % { [void]$ids.Add([uint32]$_.ProcessId) }
  if ($ids.Count) { [void][J]::Empurra($ids) }
  Start-Sleep -Milliseconds 100
}

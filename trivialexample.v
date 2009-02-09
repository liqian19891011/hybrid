Require Export Coq.Reals.Reals.
Require Export Coq.Relations.Relations.
Require Import List.
Require Import Fourier.
Require Import util.
Require Import monotonic_flow.
Require concrete.
Require abstract.
Require abstraction.
Set Implicit Arguments.

Inductive Location: Set := Up | Down.

Definition Location_eq_dec (l l': Location): {l=l'}+{l<>l'}.
  destruct l; destruct l'; auto; right; discriminate.
Defined.

Definition locations: list Location := Up :: Down :: List.nil.

Lemma locations_complete l: List.In l locations.
Proof. destruct l; compute; tauto. Qed.

Let State: Set := prod Location Point.

Definition initial (s: State): Prop := s = (Up, (0, 0)%R).

Definition invariant (s: State): Prop :=
  match fst s with
  | Up => (0 <= fst (snd s) <= 2 /\ 0 <= snd (snd s) <= 2)%R
  | Down => (1 <= fst (snd s) <= 3 /\ 1 <= snd (snd s) <= 3)%R
  end.

Lemma invariant_initial s: initial s -> invariant s.
Proof.
  destruct s. unfold initial, invariant.
  simpl. intros. inversion H. subst.
  simpl. split; auto with real.
Qed.

Definition Xflow (l: Location) (x: R) (t: Time): R :=
  match l with Up => x + t | Down => x - t end.
Definition Yflow (l: Location) (y: R) (t: Time): R :=
  match l with Up => y + t | Down => y - t end.

Lemma Xflows l: concrete.flows (Xflow l).
  intros. apply concrete.Build_flows; destruct l; simpl; intros; field.
Qed.
Lemma Yflows l: concrete.flows (Yflow l).
  intros. apply concrete.Build_flows; destruct l; simpl; intros; field.
Qed.

Lemma Xmono l: mono (Xflow l).
Proof. destruct l; [left | right]; compute; intros; fourier. Qed.
Lemma Ymono l: mono (Yflow l).
Proof. destruct l; [left | right]; compute; intros; fourier. Qed.

Definition Xflow_inv (l: Location) (x x': R): Time :=
  match l with Up => x' - x | Down => x - x' end.
Definition Yflow_inv (l: Location) (y y': R): Time :=
  match l with Up => y' - y | Down => y - y' end.

Lemma Xflow_inv_correct l x x': Xflow l x (Xflow_inv l x x') = x'.
Proof. destruct l; compute; intros; field. Qed.
Lemma Yflow_inv_correct l y y': Yflow l y (Yflow_inv l y y') = y'.
Proof. destruct l; compute; intros; field. Qed.

Definition guard (s: State) (l: Location): Prop :=
  match fst s, l with
  | Up, Down => (fst (snd s) > 1 /\ snd (snd s) > 1)%R
  | Down, Up => (fst (snd s) < 2 /\ snd (snd s) < 2)%R
  | _, _ => False
  end.

Definition reset (l l': Location) (p: Point): Point := p.

Definition concrete_system: concrete.System :=
  concrete.Build_System _ _ invariant_initial _
  (fun l => concrete.product_flows (Xflows l) (Yflows l)) guard reset.

Inductive Interval: Set := I01 | I12 | I23.

Definition Interval_eq_dec (i i': Interval): {i=i'}+{i<>i'}.
  destruct i; destruct i'; auto; right; discriminate.
Defined.

Program Definition interval_bounds (i: Interval):
  { ab: R * R | fst ab <= snd ab } :=
    match i with I01 => (0, 1) | I12 => (1, 2) | I23 => (2, 3) end.
Solve Obligations using simpl; auto with real.

Definition intervals: list Interval := I01 :: I12 :: I23 :: List.nil.

Lemma intervals_complete: forall i, List.In i intervals.
Proof. destruct i; compute; auto. Qed.

Definition absInterval (r: R): Interval :=
  if Rle_dec r 1 then I01 else
  if Rle_dec r 2 then I12 else I23.

Definition abstract_initial (l: Location) (x y: Interval): bool :=
  andb (unsumbool (Location_eq_dec l Up))
  (andb
    (unsumbool (Interval_eq_dec x I01))
    (unsumbool (Interval_eq_dec y I01))).

Lemma respectsInit (l: Location) (x y: R):
  initial (l, (x, y)) ->
  abstract_initial l (absInterval x) (absInterval y) = true.
Proof with auto with real.
  unfold initial.
  unfold abstract_initial.
  intros.
  inversion_clear H.
  simpl.
  unfold absInterval.
  destruct (Rle_dec 0 1)...
Qed.

Lemma squares_cover_invariants l x y: concrete.invariant concrete_system (l, (x, y)) ->
  in_square (x, y) (abstraction.square
    interval_bounds interval_bounds (absInterval x, absInterval y)).
Proof with auto.
  destruct l; simpl.
    unfold invariant. simpl.
    unfold absInterval.
    intros.
    destruct H. destruct H. destruct H0.
    split.
      destruct (Rle_dec x 1); simpl.
	split...
      destruct (Rle_dec x 2); simpl.
	set (Rnot_le_lt _ _ n).
	split; fourier.
      set (Rnot_le_lt _ _ n0).
      split; fourier.
    destruct (Rle_dec y 1); simpl...
    set (Rnot_le_lt _ _ n).
    destruct (Rle_dec y 2); simpl.
      split; fourier.
    set (Rnot_le_lt _ _ n0).
    split; fourier.
  unfold invariant. simpl.
  unfold absInterval.
  intros.
  destruct H. destruct H. destruct H0.
  split.
    destruct (Rle_dec x 1); simpl.
      split...
      fourier.
    set (Rnot_le_lt _ _ n).
    destruct (Rle_dec x 2); simpl...
    set (Rnot_le_lt _ _ n0).
    split; fourier.
  destruct (Rle_dec y 1); simpl.
    split; fourier.
  set (Rnot_le_lt _ _ n).
  destruct (Rle_dec y 2); simpl.
    split; fourier.
  set (Rnot_le_lt _ _ n0).
  split; fourier.
Qed.

Definition abstract_system:
  {s : abstract.System &
  {f : concrete.State concrete_system -> abstract.State s
     | abstract.Respects s f} }

  := abstraction.result Location_eq_dec
    Interval_eq_dec Interval_eq_dec abstract_initial
    locations locations_complete
    intervals intervals_complete
    intervals intervals_complete
    Xflow Yflow Xflow_inv Yflow_inv Xflows Yflows
    Xflow_inv_correct Yflow_inv_correct Xmono Ymono
    initial invariant invariant_initial guard reset
    absInterval absInterval respectsInit squares_cover_invariants.

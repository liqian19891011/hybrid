
(* Doubly-negated types as a monad: *)

Definition DN (T: Type): Prop := (T -> False) -> False.

Hint Unfold DN.

Definition DN_return {T: Type}: T -> DN T :=
  fun x f => f x.

Hint Resolve @DN_return.

Definition DN_bind {A: Type}: DN A -> forall B, (A -> DN B) -> DN B :=
  fun X Y Z P => X (fun a => Z a P).

Definition ext_eq: Prop := forall (A B: Type) (f g: A -> B), (forall x, f x = g x) -> f = g.

Lemma DN_runit: ext_eq -> forall A (x: DN A),
  DN_bind x _ DN_return = x.
Proof.
  intros.
  cut (forall y y', y = y' -> x y = x y'). firstorder.
  congruence.
Qed.

Lemma DN_lunit: ext_eq -> forall A B (a: A) (f: A -> DN B),
  DN_bind (DN_return a) _ f = f a.
Proof. firstorder. Qed.

Lemma DN_assoc A B C (a: DN A) (f: A -> DN B) (g: B -> DN C):
  DN_bind (DN_bind a _ f) _ g = DN_bind a _ (fun x => DN_bind (f x) _ g).
Proof. reflexivity. Qed.

Lemma DN_fmap {A: Type}: DN A -> forall B, (A -> B) -> DN B.
Proof. firstorder. Qed.

Lemma DN_liftM2 {A B C: Type} (f: A -> B -> C): DN A -> DN B -> DN C.
Proof. clear. firstorder. Qed.
  (* todo: this is a specialization for DN. make a normal monadic version *)

Lemma DN_exists {T: Type} {P: T -> Prop} {x: T}: DN (P x) -> DN (ex P).
Proof. firstorder. Qed.

Inductive Stable P := mkStable: (DN P -> P) -> Stable P.
  (* Using an Inductive gets us universe polymorphism, which the following
   simpler alternative does not provide: *)

(* Definition Stable P := DN P -> P. *)

Lemma DN_apply {T: Type}: DN T -> forall P, Stable P -> (T -> P) -> P.
Proof. firstorder. Qed.

Lemma Stable_neg (P: Prop): Stable (~P).
Proof. firstorder. Qed.

Lemma Stable_False: Stable False.
Proof. firstorder. Qed.

Lemma Stable_True: Stable True.
Proof. firstorder. Qed.

Hint Immediate Stable_False Stable_True.

Lemma stable_conjunction (A B: Prop): Stable A -> Stable B -> Stable (A /\ B).
Proof. firstorder. Qed.

Hint Resolve stable_conjunction.

Lemma forall_stable (T: Type) (P: T -> Type): (forall x, Stable (P x)) -> Stable (forall x, P x).
Proof. firstorder. Qed.

Hint Resolve forall_stable.

Require Import util.

Lemma decision_stable P: decision P -> Stable P.
Proof. firstorder. Qed.

Require Import CRreal Classic.

Lemma Qle_dec x y: decision (Qle x y).
  intros.
  destruct (Qlt_le_dec y x); [right | left]; [apply Qlt_not_le |]; assumption.
Defined.
  (* Todo: Don't I have this elsewhere? *)

Lemma CRnonNeg_stable x: Stable (CRnonNeg x).
Proof with auto.
  unfold CRnonNeg.
  intros.
  constructor.
  intros.
  destruct (Qle_dec (-e) (approximate x e))...
  elimtype False...
Qed.

Hint Resolve CRnonNeg_stable.

Lemma CRle_stable (x y: CR): Stable (CRle x y).
Proof. unfold CRle. auto. Qed.

Hint Resolve CRle_stable.

Lemma CReq_stable (x y: CR): Stable (x == y)%CR.
Proof.
  unfold st_eq. simpl.
  unfold regFunEq, ball. simpl.
  unfold Qmetric.Qball, AbsSmall.
  auto using decision_stable, Qle_dec.
Qed.

Open Local Scope CR_scope.

Lemma DN_or P Q: Not ((Not P) /\ (Not Q)) -> DN (P + Q).
Proof. firstorder. Qed.

Definition CRle_cases: forall x y: CR, x <= y -> DN ((x < y) or (x == y))
  := leEq_less_or_equal CRasCOrdField.

(* What on earth is the point of COr? Is it not the exact same as sum? *)

Definition CRle_dec: forall (x y: CR), DN ((x<=y) or (y<=x))
  := leEq_or_leEq CRasCOrdField.

Lemma CRle_lt_dec x y: DN ((x <= y) + (y < x)).
Proof with intuition.
  intros.
  apply (DN_bind (CRle_dec x y))...
  apply (DN_fmap (CRle_cases _ _ b))...
  left.
  rewrite b0.
  apply CRle_refl.
Qed.

Lemma CR_trichotomy x y: DN ((x == y) + ((x < y) + (y < x))).
Proof with intuition.
  intros.
  apply (DN_bind (CRle_lt_dec x y)). intros [A | A]...
  apply (DN_fmap (CRle_cases _ _ A))...
Qed.
